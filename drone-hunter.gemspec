Gem::Specification.new do |gem|
    tag = if ENV["GITHUB_WORKFLOW"]
        `git describe --tags --always`
    else
        `git describe --tags --abbrev=0`
    end.chomp

    if tag.match?(/[.]/)
        tag = "0.0.0+" + tag
    end
  
    gem.name          = 'drone-hunter'
    gem.homepage      = 'https://github.com/colstrom/drone-hunter'
    gem.summary       = 'Hunts for Drone CI files across many repositories'
  
    gem.version       = "#{tag}"
    gem.licenses      = ['MIT']
    gem.authors       = ['Chris Olstrom']
    gem.email         = 'chris@olstrom.com'
  
    # gem.cert_chain    = ['trust/certificates/colstrom.pem']
    # gem.signing_key   = File.expand_path ENV.fetch 'GEM_SIGNING_KEY'
  
    gem.files         = `git ls-files -z`.split("\x0")
    gem.test_files    = `git ls-files -z -- {test,spec,features}/*`.split("\x0")
    gem.executables   = `git ls-files -z -- bin/*`.split("\x0").map { |f| File.basename(f) }
  
    gem.require_paths = ['lib']
  
    gem.add_runtime_dependency 'octokit', '~> 4.25', '>= 4.25.1'
    gem.add_runtime_dependency 'moneta',  '~> 1.5',  '>= 1.5.1'
end
