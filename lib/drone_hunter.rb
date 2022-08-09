# SPDX-License-Identifier: MIT

#########################
# Ruby Standard Library #
#########################

require "base64"
require "logger"
require "set"
require "yaml"

#########################
# External Dependencies #
#########################

require "moneta"
require "octokit"

class DroneHunter
    def initialize(**options)
        @log    ||= options.fetch(:log) { Logger.new(STDERR) }
        @github ||= options.fetch(:client) { Octokit::Client.new(auto_paginate: true) }
        @cache  ||= options.fetch(:cache) { Moneta.new(:File, dir: 'drone-hunter.cache') }
        @owners ||= Set.new(options.fetch(:owners, []))
        @ignoring ||= { archived: false }.merge(options.fetch(:ignore, {}))
        @match  ||= { basename: /drone/, suffix: /[.]ya?ml$/ }.merge(options.fetch(:match, {}))
    end

    attr_reader :log
    attr_reader :github
    attr_reader :cache
    attr_reader :owners
    attr_reader :ignoring
    attr_reader :match

    def ignoring_archived?
        ignoring.fetch(:archived, false)
    end

    def cached(key, *rest, &block)
        if cache.key?(key)
            log.debug("(cache) #{key}")
            cache.fetch(key)
        else
            log.info("(fetch) #{key}")
            cache.store(key, block.call(*rest))
        end
    end

    def repositories(owner = nil)
        case owner
        when String then cached("repositories/#{owner}") { github.repositories(owner) }
        when nil    then owners.flat_map { |owner| repositories(owner) }.reject do |repo|
            ignoring_archived? && repo.archived
        end
        else raise TypeError
        end
    end

    def branches(repo = nil)
        case repo
        when String            then cached("branches/#{repo}") { github.branches(repo) }
        when Sawyer::Resource  then branches(repo.full_name)
        when nil               then repositories.flat_map { |repo| branches(repo) }
        else raise TypeError
        end
    end

    def trees
        repositories.map do |repo|
            tree_sha = branches(repo.full_name).find do |branch|
                branch.name == repo.default_branch
            end&.commit&.sha
            
            next unless tree_sha
            repo = repo.full_name

            {
                repo => cached("tree/#{repo}/#{tree_sha}") { github.tree(repo, tree_sha) }.tree
            }
        end.compact.reduce(&:merge)
    end

    def blobs
        trees.map do |repo, tree|
            blobs = tree
                .select { |entry| entry.path.match?(match[:suffix]) }
                .select { |entry| entry.path.match?(match[:basename]) }
                .map do |entry| 
                    {
                        entry.path => cached("blob/#{repo}/#{entry.sha}") { github.blob(repo, entry.sha) }
                    }
                end
            next if blobs.empty?

            {
                repo => blobs.reduce(&:merge)
            }
        end.compact.reduce(&:merge)
    end

    def dronefiles
        blobs.flat_map do |repo, blobs|
            blobs.map do |path, blob|
                case blob[:encoding]
                when "base64"
                    {
                        "repository" => repo,
                        "path"       => path,
                        "sha"        => blob[:sha],
                        "content"    => Base64::decode64(blob[:content])
                    }
                else raise EncodingError
                end
            end
        end
    end
end
