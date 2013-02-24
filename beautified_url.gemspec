Gem::Specification.new do |s|
  s.name        = 'beautified_url'
  s.version     = '0.0.1'
  s.date        = '2012-02-24'
  s.summary     = "BeautifiedUrl"
  s.description = "Basic tool which provides feature of generating tokens which can be used in url for identifying resource(uniquely of uniquely within a scope) instead of :id. Just add another field which starts with _bu_ of one or many existing fields to make it all happen. Example: For a blog post, if you have a 'title' field and want to beautify and use it instead of :id add another field like '_bu_title' and now modify routes and application to refer and fetch resource from '_bu_title' field."
  s.authors     = ["Praveen Kumar Sinha"]
  s.email       = 'praveen.kumar.sinha@gmail.com'
  s.files       = ["lib/beautified_url.rb"]
  s.homepage    = 'https://github.com/praveenkumarsinha/BeautifiedUrl'
end

