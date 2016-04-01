Pod::Spec.new do |s|

s.name         = "FZZImagePickerKit"
s.version      = "0.0.13"
s.summary      = "イメージピッカーをかんたんに作成"
s.homepage     = "http://shtnkgm.github.io/"
s.license      = { :type => "MIT", :file => "LICENSE.txt" }
s.author       = 'Shota Nakagami'
s.platform     = :ios, "8.0"
s.requires_arc = true
s.source       = { :git => "https://shtnkgm@bitbucket.org/shtnkgm/fzzimagepickerkit.git", :tag => s.version }
s.source_files = "FZZImagePickerKit/FZZ*.{h,m}", "FZZImagePickerKit/NSString+FZZImagePickerKitLocalized.{h,m}"
# s.resources    = ["FZZImagePickerKit/*.{png}"]
s.resource_bundles = { 'FZZImagePickerKit' => ["FZZImagePickerKit/*.lproj"]}
s.framework  = 'Foundation', 'UIKit', 'AssetsLibrary', 'AVFoundation'
s.dependency 'SVProgressHUD'

end