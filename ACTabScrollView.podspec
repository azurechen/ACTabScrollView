Pod::Spec.new do |s|

  s.name         = "ACTabScrollView"
  s.version      = "0.2.4"
  s.summary      = "A fancy pager UI extends UIScrollView with elegant, smooth and synchronized scrollable tabs."

  s.description  = <<-DESC
                   A fancy pager UI extends UIScrollView with elegant, smooth and synchronized scrollable tabs.
                   DESC

  s.homepage     = "https://github.com/azurechen/ACTabScrollView"
  s.license      = "MIT"
  s.author       = { "Azure Chen" => "azure517981@gmail.com" }
  s.source       = { :git => "https://github.com/azurechen/ACTabScrollView.git", :tag => "v0.2.4" }
  s.platforms = { :ios => "8.0" }

  s.source_files  = "Sources/**/*.swift"

end
