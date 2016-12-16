Pod::Spec.new do |s|

  s.name         = "ACTabScrollView"
  s.version      = "0.2.6"
  s.summary      = "A fancy `Menu` and `Pager` UI extends `UIScrollView` with elegant, smooth and synchronized scrolling `tabs`."

  s.description  = <<-DESC
                   A fancy `Menu` and `Pager` UI extends `UIScrollView` with elegant, smooth and synchronized scrolling `tabs`.
                   DESC

  s.homepage     = "https://github.com/azurechen/ACTabScrollView"
  s.license      = "MIT"
  s.author       = { "Azure Chen" => "azure517981@gmail.com" }
  s.source       = { :git => "https://github.com/azurechen/ACTabScrollView.git", :tag => "v0.2.6" }
  s.platforms = { :ios => "8.0" }

  s.source_files  = "Sources/**/*.swift"

end
