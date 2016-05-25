Pod::Spec.new do |s|

  s.name         = "ACTabScrollView"
  s.version      = "0.2.3"
  s.summary      = "A fancy pager UI extends UIScrollView with elegant, smooth and synchronized scrollable tabs."

  s.description  = <<-DESC
                   A fancy pager UI extends UIScrollView with elegant, smooth and synchronized scrollable tabs.
                   DESC

  s.homepage     = "https://github.com/azurechen/ACTabScrollView"
  s.license      = "MIT"
  s.author       = { "Azure Chen" => "azure517981@gmail.com" }
  s.source       = { :git => "https://github.com/azurechen/ACTabScrollView.git", :tag => s.version.to_s }

  s.source_files  = "Sources/**/*.swift"

end
