require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/json'
require 'openssl'

require 'net/http'

module BaneryStats
  mattr_accessor :api_token

  class JsonGet
    def self.perform(url)
      new(url).perform
    end

    attr_reader :url

    def initialize(url)
      @url = url
    end

    def perform
      ActiveSupport::JSON.decode(response.body)
    end

    def response
      http.request(request)
    end

    def http
      Net::HTTP.new(uri.host, uri.port).tap do |h|
        h.use_ssl = true
      end
    end

    def uri
      URI.parse(url)
    end

    def request
      Net::HTTP::Get.new(uri.request_uri).tap do |r|
        r['X-Kanbanery-ApiToken'] = BaneryStats.api_token or raise "You must set BaneryStats.api_token to your API token"
      end
    end
  end

  class OutputSummary
    def self.run
      new.run
    end

    def run
      workspaces.each do |workspace|
        log("WORKSPACE #{workspace.name} #projects: #{workspace.projects.size}")
        workspace.projects.each do |workspace_project|
          project_tasks = project_tasks(workspace.name, workspace_project.id)
          tasks_count = project_tasks.size
          log("#{tasks_count.to_s.rjust(5)} #{workspace_project.name}") if tasks_count > 0
        end
      end
    end

    def workspaces
      data = JsonGet.perform(workspace_url)
      data.collect do |workspace_data|
        projects = workspace_data["projects"].collect { |workspace_project| OpenStruct.new(id: workspace_project["id"], name: workspace_project["name"]) }
        OpenStruct.new(id: workspace_data["id"], name: workspace_data["name"], projects: projects)
      end
    end

    def project_tasks(workspace_name, project_id)
      data = JsonGet.perform(project_tasks_url(workspace_name, project_id))
      data.keep_if { |d| d.has_key?("owner_id") && d["owner_id"] == own_user_id }
      data
    end

    def own_user_id
      @own_user_id ||=
        begin
          data = JsonGet.perform(own_user_info_url)
          data["id"]
        end
    end

    def log(msg)
      puts msg
    end

    def workspace_url
      "https://kanbanery.com/api/v1/user/workspaces.json/"
    end

    def project_tasks_url(workspace_name, project_id)
      "https://#{workspace_name}.kanbanery.com/api/v1/projects/#{project_id}/tasks.json"
    end

    def own_user_info_url
      "https://avarteq.kanbanery.com/api/v1/user.json"
    end
  end
end

BaneryStats.api_token = ENV['KANBANERY_API_TOKEN']

BaneryStats::OutputSummary.run
