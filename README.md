ACTabScrollView
===============

A fancy `pager` UI extends `UIScrollView` with elegant, smooth and synchronized scrolling `tabs`.

DEMO
----

<img src="./Screenshots/demo-1.gif" width = "288" alt="Demo" />
<img src="./Screenshots/demo-2.gif" width = "288" alt="Demo" />
<img src="./Screenshots/demo-3.gif" width = "288" alt="Demo" />

User can interact with the UI by some different gestures. The `tabs` and `pages` will always scroll `synchronously`.

* `Swipe` pages normally
* `Drag` tabs can quickly move pages
* `Click` a tab to change to that page

You can also use `changePageToIndex` method to scroll pages programmatically.

Usage
-----

###Add an Object of ACTabScrollView

Drag a `UIView` object  onto the Interface Builder and set the `Class` to extends `ACTabScrollView ` in `XIB` or `Storyboard`.

<img src="./Screenshots/usage-1.png" width = "800" alt="Demo" />

You can also set properties at `Interface Builder`.

And remember to declare the `IBOutlet`.

```swift
@IBOutlet weak var tabScrollView: ACTabScrollView!
```

###Set Properties

All the following properties are `optional`. It provides more flexibility to customize. But it will be fine if you don't change any property.

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    tabScrollView.defaultPage = 3
    tabScrollView.arrowIndicator = true
    tabScrollView.tabSectionHeight = 40
    tabScrollView.tabSectionBackgroundColor = UIColor.whiteColor()
    tabScrollView.contentSectionBackgroundColor = UIColor.whiteColor()
    tabScrollView.tabGradient = true
    tabScrollView.pagingEnabled = true
    tabScrollView.cachedPageLimit = 3
    
    ...
}
```

###Delegate and DataSource

Set `Delegate` and `DataSource` first in `viewDidLoad()`, the usage is similar to `UITableView`.

```swift
override func viewDidLoad() {
    ...
    
    tabScrollView.delegate = self
    tabScrollView.dataSource = self
    
    ...
}
```

Prepare all the content views in `viewDidLoad()` may be a good idea. We had better not create the content view at each page change because it may cause performance issues.

```swift
override func viewDidLoad() {
    ...
    
	// create content views from storyboard
	let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
	for i in 0 ..< /* number of pages */ {
	    let vc = storyboard.instantiateViewControllerWithIdentifier("ContentViewController") as! ContentViewController
	    
	    /* set somethings for vc */
	    
	    addChildViewController(vc) // don't forget, it's very important
	    contentViews.append(vc.view)
	}
	
	...
}
```

And implement methods

```swift
// MARK: ACTabScrollViewDelegate
func tabScrollView(tabScrollView: ACTabScrollView, didChangePageTo index: Int) {
    print(index)
}
    
func tabScrollView(tabScrollView: ACTabScrollView, didScrollPageTo index: Int) {
}
    
// MARK: ACTabScrollViewDataSource
func numberOfPagesInTabScrollView(tabScrollView: ACTabScrollView) -> Int {
    return /* number of pages */
}
    
func tabScrollView(tabScrollView: ACTabScrollView, tabViewForPageAtIndex index: Int) -> UIView {
    // create a label
    let label = UILabel()
    label.text = /* tab title at {index} */
    label.textAlignment = .Center
    
    // if the size of your tab is not fixed, you can adjust the size by the following way.
    label.sizeToFit() // resize the label to the size of content
    label.frame.size = CGSize(
        width: label.frame.size.width + 28, 
        height: label.frame.size.height + 36) // add some paddings
    
    return label
}
    
func tabScrollView(tabScrollView: ACTabScrollView, contentViewForPageAtIndex index: Int) -> UIView {
    return contentViews[index]
}
```

The usage tutorial is finished, you can see more details and example at `ACTabScrollView/NewsViewController.swift`

How to Install
--------------

###CocoaPods

If you didn't use [CocoaPods](http://cocoapods.org) before, install it first.

```bash
$ gem install cocoapods
$ pod setup
```

Create a file named `Podfile` in your project folder if this file doesn't exist. And append the following line into your `Podfile`.

```Swift
pod 'ACTabScrollView', :git => 'https://github.com/azurechen/ACTabScrollView.git'
```

Then, run this command. 🎉

```bash
$ pod install
```

###Manual

Drag these two files into your project.

* `Sources/ACTabScrollView.swift`
* `Sources/ACTabScrollView+Protocol.swift`

And you can use `ACTabScrollView`. 🎉
