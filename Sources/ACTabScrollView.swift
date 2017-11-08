//
//  ACTabScrollView.swift
//  ACTabScrollView
//
//  Created by AzureChen on 2015/8/19.
//  Copyright (c) 2015 AzureChen. All rights reserved.
//

//  TODO:
//   1. Performace improvement
//   2. Test reloadData function
//   3. Tabs in the bottom
//   4. Bottom line or shadow
//   5. Support Carthage

import UIKit

@IBDesignable
open class ACTabScrollView: UIView, UIScrollViewDelegate {
    
    // MARK: Public Variables
    @IBInspectable open var defaultPage: Int = 0
    @IBInspectable open var tabSectionHeight: CGFloat = -1
    @IBInspectable open var tabSectionBackgroundColor: UIColor = UIColor.white
    @IBInspectable open var contentSectionBackgroundColor: UIColor = UIColor.white
    @IBInspectable open var tabGradient: Bool = true
    @IBInspectable open var arrowIndicator: Bool = false
    @IBInspectable open var pagingEnabled: Bool = true {
        didSet {
            contentSectionScrollView.isPagingEnabled = pagingEnabled
        }
    }
    @IBInspectable open var cachedPageLimit: Int = 3
    
    open var delegate: ACTabScrollViewDelegate?
    open var dataSource: ACTabScrollViewDataSource?
    
    // MARK: Private Variables
    fileprivate var tabSectionScrollView: UIScrollView!
    fileprivate var contentSectionScrollView: UIScrollView!
    fileprivate var arrowView: ArrowView!
    
    fileprivate var cachedPageTabs: [Int: UIView] = [:]
    fileprivate var cachedPageContents: CacheQueue<Int, UIView> = CacheQueue()
    fileprivate var realcachedPageLimit: Int {
        var limit = 3
        if (cachedPageLimit > 3) {
            limit = cachedPageLimit
        } else if (cachedPageLimit < 1) {
            limit = numberOfPages
        }
        return limit
    }
    
    fileprivate var isStarted = false
    fileprivate var pageIndex: Int!
    fileprivate var prevPageIndex: Int?
    
    fileprivate var isWaitingForPageChangedCallback = false
    fileprivate var pageChangedCallback: (() -> Void)?
    
    // MARK: DataSource
    fileprivate var numberOfPages = 0
    
    fileprivate func widthForTabAtIndex(_ index: Int) -> CGFloat {
        return cachedPageTabs[index]?.frame.width ?? 0
    }
    
    fileprivate func tabViewForPageAtIndex(_ index: Int) -> UIView? {
        return dataSource?.tabScrollView(self, tabViewForPageAtIndex: index)
    }
    
    fileprivate func contentViewForPageAtIndex(_ index: Int) -> UIView? {
        return dataSource?.tabScrollView(self, contentViewForPageAtIndex: index)
    }
    
    // MARK: Init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    fileprivate func initialize() {
        // init views
        tabSectionScrollView = UIScrollView()
        contentSectionScrollView = UIScrollView()
        arrowView = ArrowView(frame: CGRect(x: 0, y: 0, width: 30, height: 10))
        
        self.addSubview(tabSectionScrollView)
        self.addSubview(contentSectionScrollView)
        self.addSubview(arrowView)
        
        tabSectionScrollView.isPagingEnabled = false
        tabSectionScrollView.showsHorizontalScrollIndicator = false
        tabSectionScrollView.showsVerticalScrollIndicator = false
        tabSectionScrollView.delegate = self
        
        contentSectionScrollView.isPagingEnabled = pagingEnabled
        contentSectionScrollView.showsHorizontalScrollIndicator = false
        contentSectionScrollView.showsVerticalScrollIndicator = false
        contentSectionScrollView.delegate = self
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        // reset status and stop scrolling immediately
        if (isStarted) {
            isStarted = false
            stopScrolling()
        }
        
        // set custom attrs
        tabSectionScrollView.backgroundColor = self.tabSectionBackgroundColor
        contentSectionScrollView.backgroundColor = self.contentSectionBackgroundColor
        arrowView.arrorBackgroundColor = self.tabSectionBackgroundColor
        arrowView.isHidden = !arrowIndicator
        
        // first time setup pages
        setupPages()
        
        // async necessarily
        DispatchQueue.main.async {
            // first time set defaule pageIndex
            self.initWithPageIndex(self.pageIndex ?? self.defaultPage)
            self.isStarted = true
            
            // load pages
            self.lazyLoadPages()
        }
    }
    
    override open func prepareForInterfaceBuilder() {
        let textColor = UIColor(red: 203.0 / 255, green: 203.0 / 255, blue: 203.0 / 255, alpha: 1.0)
        let tabSectionHeight = self.tabSectionHeight >= 0 ? self.tabSectionHeight : 64
        
        // labels
        let tabSectionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: tabSectionHeight))
        let contentSectionLabel = UILabel(frame: CGRect(x: 0, y: tabSectionHeight + 1, width: self.frame.width, height: self.frame.height - tabSectionHeight - 1))
        
        tabSectionLabel.text = "Tab Section"
        tabSectionLabel.textColor = textColor
        tabSectionLabel.textAlignment = .center
        if #available(iOS 8.2, *) {
            tabSectionLabel.font = UIFont.systemFont(ofSize: 27, weight: UIFont.Weight.heavy)
        } else {
            tabSectionLabel.font = UIFont.systemFont(ofSize: 27)
        }
        tabSectionLabel.backgroundColor = tabSectionBackgroundColor
        contentSectionLabel.text = "Content Section"
        contentSectionLabel.textColor = textColor
        contentSectionLabel.textAlignment = .center
        if #available(iOS 8.2, *) {
            contentSectionLabel.font = UIFont.systemFont(ofSize: 27, weight: UIFont.Weight.heavy)
        } else {
            contentSectionLabel.font = UIFont.systemFont(ofSize: 27)
        }
        contentSectionLabel.backgroundColor = contentSectionBackgroundColor
        
        // rect and seperator
        let rectView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        rectView.layer.borderWidth = 1
        rectView.layer.borderColor = textColor.cgColor
        
        let seperatorView = UIView(frame: CGRect(x: 0, y: tabSectionHeight, width: self.frame.width, height: 1))
        seperatorView.backgroundColor = textColor
        
        // arrow
        arrowView.frame.origin = CGPoint(x: (self.frame.width - arrowView.frame.width) / 2, y: tabSectionHeight)
        
        // add subviews
        self.addSubview(tabSectionLabel)
        self.addSubview(contentSectionLabel)
        self.addSubview(rectView)
        self.addSubview(seperatorView)
        self.addSubview(arrowView)
    }
    
    // MARK: - Tab Clicking Control
    @objc func tabViewDidClick(_ sensor: UITapGestureRecognizer) {
        activedScrollView = tabSectionScrollView
        moveToIndex(sensor.view!.tag, animated: true)
    }
    
    @objc func tabSectionScrollViewDidClick(_ sensor: UITapGestureRecognizer) {
        activedScrollView = tabSectionScrollView
        moveToIndex(pageIndex, animated: true)
    }
    
    // MARK: - Scrolling Control
    fileprivate var activedScrollView: UIScrollView?
    
    // scrolling animation begin by dragging
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // stop current scrolling before start another scrolling
        stopScrolling()
        // set the activedScrollView
        activedScrollView = scrollView
    }
    
    // scrolling animation stop with decelerating
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        moveToIndex(currentPageIndex(), animated: true)
    }
    
    // scrolling animation stop without decelerating
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            moveToIndex(currentPageIndex(), animated: true)
        }
    }
    
    // scrolling animation stop programmatically
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if (isWaitingForPageChangedCallback) {
            isWaitingForPageChangedCallback = false
            pageChangedCallback?()
        }
    }
    
    // scrolling
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentIndex = currentPageIndex()
        
        if (scrollView == activedScrollView) {
            let speed = self.frame.width / widthForTabAtIndex(currentIndex)
            let halfWidth = self.frame.width / 2
            
            var tabsWidth: CGFloat = 0
            var contentsWidth: CGFloat = 0
            for i in 0 ..< currentIndex {
                tabsWidth += widthForTabAtIndex(i)
                contentsWidth += self.frame.width
            }
            
            if (scrollView == tabSectionScrollView) {
                contentSectionScrollView.contentOffset.x = ((tabSectionScrollView.contentOffset.x + halfWidth - tabsWidth) * speed) + contentsWidth - halfWidth
            }
            
            if (scrollView == contentSectionScrollView) {
                tabSectionScrollView.contentOffset.x = ((contentSectionScrollView.contentOffset.x + halfWidth - contentsWidth) / speed) + tabsWidth - halfWidth
            }
            updateTabAppearance()
        }
        
        if (isStarted && pageIndex != currentIndex) {
            // set index
            pageIndex = currentIndex
            
            // lazy loading
            lazyLoadPages()
            
            // callback
            delegate?.tabScrollView(self, didScrollPageTo: currentIndex)
        }
    }
    
    // MARK: Public Methods
//    func scroll(offsetX: CGFloat) {
//    }
    
    open func reloadData() {
        // setup pages
        setupPages()
        
        // load pages
        lazyLoadPages()
    }
    
    open func changePageToIndex(_ index: Int, animated: Bool) {
        activedScrollView = tabSectionScrollView
        moveToIndex(index, animated: animated)
    }
    
    open func changePageToIndex(_ index: Int, animated: Bool, completion: @escaping (() -> Void)) {
        isWaitingForPageChangedCallback = true
        pageChangedCallback = completion
        changePageToIndex(index, animated: animated)
    }
    
    // MARK: Private Methods
    fileprivate func stopScrolling() {
        tabSectionScrollView.setContentOffset(tabSectionScrollView.contentOffset, animated: false)
        contentSectionScrollView.setContentOffset(contentSectionScrollView.contentOffset, animated: false)
    }
    
    fileprivate func initWithPageIndex(_ index: Int) {
        // set pageIndex
        pageIndex = index
        prevPageIndex = pageIndex
        
        // init UI
        if (numberOfPages != 0) {
            var tabOffsetX = 0 as CGFloat
            var contentOffsetX = 0 as CGFloat
            for i in 0 ..< index {
                tabOffsetX += widthForTabAtIndex(i)
                contentOffsetX += self.frame.width
            }
            // set default position of tabs and contents
            tabSectionScrollView.contentOffset = CGPoint(x: tabOffsetX - (self.frame.width - widthForTabAtIndex(index)) / 2, y: tabSectionScrollView.contentOffset.y)
            contentSectionScrollView.contentOffset = CGPoint(x: contentOffsetX, y: contentSectionScrollView.contentOffset.y)
            updateTabAppearance(animated: false)
        }
    }
    
    fileprivate func currentPageIndex() -> Int {
        let width = self.frame.width
        var currentPageIndex = Int((contentSectionScrollView.contentOffset.x + (0.5 * width)) / width)
        if (currentPageIndex < 0) {
            currentPageIndex = 0
        } else if (currentPageIndex >= self.numberOfPages) {
            currentPageIndex = self.numberOfPages - 1
        }
        return currentPageIndex
    }

    fileprivate func setupPages() {
        // reset number of pages
        numberOfPages = dataSource?.numberOfPagesInTabScrollView(self) ?? 0
        
        // clear all caches
        cachedPageTabs.removeAll()
        for subview in tabSectionScrollView.subviews {
            subview.removeFromSuperview()
        }
        cachedPageContents.removeAll()
        for subview in contentSectionScrollView.subviews {
            subview.removeFromSuperview()
        }
        
        if (numberOfPages != 0) {
            // cache tabs and get the max height
            var maxTabHeight: CGFloat = 0
            for i in 0 ..< numberOfPages {
                if let tabView = tabViewForPageAtIndex(i) {
                    // get max tab height
                    if (tabView.frame.height > maxTabHeight) {
                        maxTabHeight = tabView.frame.height
                    }
                    cachedPageTabs[i] = tabView
                }
            }
            
            let tabSectionHeight = self.tabSectionHeight >= 0 ? self.tabSectionHeight : maxTabHeight
            let contentSectionHeight = self.frame.size.height - tabSectionHeight
            
            // setup tabs first, and set contents later (lazyLoadPages)
            var tabSectionScrollViewContentWidth: CGFloat = 0
            for i in 0 ..< numberOfPages {
                if let tabView = cachedPageTabs[i] {
                    tabView.frame = CGRect(
                        origin: CGPoint(
                            x: tabSectionScrollViewContentWidth,
                            y: tabSectionHeight - tabView.frame.height),
                        size: tabView.frame.size)
                    
                    // bind event
                    tabView.tag = i
                    tabView.isUserInteractionEnabled = true
                    tabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ACTabScrollView.tabViewDidClick(_:))))
                    tabSectionScrollView.addSubview(tabView)
                }
                tabSectionScrollViewContentWidth += widthForTabAtIndex(i)
            }
            
            // reset the fixed size of tab section
            tabSectionScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: tabSectionHeight)
            tabSectionScrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ACTabScrollView.tabSectionScrollViewDidClick(_:))))
            tabSectionScrollView.contentInset = UIEdgeInsets(
                top: 0,
                left: (self.frame.width / 2) - (widthForTabAtIndex(0) / 2),
                bottom: 0,
                right: (self.frame.width / 2) - (widthForTabAtIndex(numberOfPages - 1) / 2))
            tabSectionScrollView.contentSize = CGSize(width: tabSectionScrollViewContentWidth, height: tabSectionHeight)
            
            // reset the fixed size of content section
            contentSectionScrollView.frame = CGRect(x: 0, y: tabSectionHeight, width: self.frame.size.width, height: contentSectionHeight)
            
            // reset the origin of arrow view
            arrowView.frame.origin = CGPoint(x: (self.frame.width - arrowView.frame.width) / 2, y: tabSectionHeight)
        }
    }
    
    fileprivate func updateTabAppearance(animated: Bool = true) {
        if (tabGradient) {
            if (numberOfPages != 0) {
                for i in 0 ..< numberOfPages {
                    var alpha: CGFloat = 1.0
                    
                    let offset = abs(i - pageIndex)
                    if (offset > 1) {
                        alpha = 0.2
                    } else if (offset > 0) {
                        alpha = 0.4
                    } else {
                        alpha = 1.0
                    }
                    
                    if let tab = self.cachedPageTabs[i] {
                        if (animated) {
                            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                                tab.alpha = alpha
                                return
                            }, completion: nil)
                        } else {
                            tab.alpha = alpha
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func moveToIndex(_ index: Int, animated: Bool) {
        if (index >= 0 && index < numberOfPages) {
            if (pagingEnabled) {
                // force stop
                stopScrolling()
                
                if (activedScrollView == nil || activedScrollView == tabSectionScrollView) {
                    activedScrollView = contentSectionScrollView
                    contentSectionScrollView.scrollRectToVisible(CGRect(
                        origin: CGPoint(x: self.frame.width * CGFloat(index), y: 0),
                        size: self.frame.size), animated: true)
                }
            }
            
            if (prevPageIndex != index) {
                prevPageIndex = index
                // callback
                delegate?.tabScrollView(self, didChangePageTo: index)
            }
        }
    }
    
    fileprivate func lazyLoadPages() {
        if (numberOfPages != 0) {
            let offset = 1
            let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
            let rightBoundIndex = pageIndex + offset < numberOfPages ? pageIndex + offset : numberOfPages - 1
            
            var currentContentWidth: CGFloat = 0.0
            for i in 0 ..< numberOfPages {
                let width = self.frame.width
                if (i >= leftBoundIndex && i <= rightBoundIndex) {
                    let frame = CGRect(
                        x: currentContentWidth,
                        y: 0,
                        width: width,
                        height: contentSectionScrollView.frame.size.height)
                    insertPageAtIndex(i, frame: frame)
                }
                
                currentContentWidth += width
            }
            contentSectionScrollView.contentSize = CGSize(width: currentContentWidth, height: contentSectionScrollView.frame.height)
            
            // remove older caches
            while (cachedPageContents.count > realcachedPageLimit) {
                if let (_, view) = cachedPageContents.popFirst() {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    fileprivate func insertPageAtIndex(_ index: Int, frame: CGRect) {
        if (cachedPageContents[index] == nil) {
            if let view = contentViewForPageAtIndex(index) {
                view.frame = frame
                cachedPageContents[index] = view
                contentSectionScrollView.addSubview(view)
            }
        } else {
            cachedPageContents.awake(index)
        }
    }
    
}

public struct CacheQueue<Key: Hashable, Value> {
    
    var keys: Array<Key> = []
    var values: Dictionary<Key, Value> = [:]
    var count: Int {
        return keys.count
    }
    
    subscript(key: Key) -> Value? {
        get {
            return values[key]
        }
        set {
            // key/value pair exists, delete it first
            if let index = keys.index(of: key) {
                keys.remove(at: index)
            }
            // append key
            if (newValue != nil) {
                keys.append(key)
            }
            // set value
            values[key] = newValue
        }
    }
    
    mutating func awake(_ key: Key) {
        if let index = keys.index(of: key) {
            keys.remove(at: index)
            keys.append(key)
        }
    }
    
    mutating func popFirst() -> (Key, Value)? {
        let key = keys.removeFirst()
        if let value = values.removeValue(forKey: key) {
            return (key, value)
        } else {
            return nil
        }
    }
    
    mutating func removeAll() {
        keys.removeAll()
        values.removeAll()
    }
    
}

class ArrowView : UIView {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    var rect: CGRect!
    var arrorBackgroundColor: UIColor?
    
    var midX: CGFloat { return rect.midX }
    var midY: CGFloat { return rect.midY }
    var maxX: CGFloat { return rect.maxX }
    var maxY: CGFloat { return rect.maxY }
    
    override func draw(_ rect: CGRect) {
        self.rect = rect
        
        let ctx = UIGraphicsGetCurrentContext()
        
        ctx?.beginPath()
        ctx?.move(to: CGPoint(x: 0, y: 0))
        ctx?.addQuadCurve(to: CGPoint(x:maxX * 0.2 , y: maxY * 0.2), control: CGPoint(x: maxX * 0.12, y: 0))
        ctx?.addLine(to: CGPoint(x: midX - maxX * 0.05, y: maxY * 0.9))
        ctx?.addQuadCurve(to: CGPoint(x: midX + maxX * 0.05, y: maxY * 0.9), control: CGPoint(x: midX, y: maxY))
        ctx?.addLine(to: CGPoint(x: maxX * 0.8, y: maxY * 0.2))
        ctx?.addQuadCurve(to: CGPoint(x: maxX, y: 0), control: CGPoint(x: maxX * 0.88, y: 0))
        ctx?.closePath()
        
        ctx?.setFillColor((arrorBackgroundColor?.cgColor)!)
        ctx?.fillPath();
    }
    
}
