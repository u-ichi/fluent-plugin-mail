# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Yuichi UEMURA", "Naotoshi Seo"]
  gem.email         = ["yuichi.u@gmail.com", "sonots@gmail.com"]
  gem.description   = %q{output plugin for Mail}
  gem.summary       = %q{output plugin for Mail}
  gem.homepage      = "https://github.com/u-ichi/fluent-plugin-mail"
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-mail"
  gem.require_paths = ["lib"]
  gem.version       = '0.2.4'
  gem.license       = "Apache-2.0"

  gem.add_runtime_dependency "fluentd", [">= 0.14.8", "< 2"]
  gem.add_development_dependency "rake"
  gem.add_development_dependency "test-unit"
end
