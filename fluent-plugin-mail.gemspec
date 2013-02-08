# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Yuichi UEMURA"]
  gem.email         = ["yuichi.u@gmail.com"]
  gem.description   = %q{output plugin for Mail}
  gem.summary       = %q{output plugin for Mail}
  gem.homepage      = "https://github.com/u-ichi/fluent-plugin-mail"
  gem.rubyforge_project = "fluent-plugin-mail"
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-mail"
  gem.require_paths = ["lib"]
  gem.version       = '0.0.1'
  gem.add_development_dependency "fluentd"
  gem.add_development_dependency "rake"
  gem.add_runtime_dependency "fluentd"
end

