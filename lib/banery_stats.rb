require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/json'

require 'net/http'

module BaneryStats
  mattr_accessor :api_token

  class OutputSummary
    def self.run
      new.run
    end

    def run
      workspaces.each do |workspace|
        puts "WORKSPACE #{workspace.name} #projects: #{workspace.projects.size}"
        workspace.projects.each do |workspace_project|
          project_tasks = project_tasks(workspace.name, workspace_project.id)
          puts "#{project_tasks.size.to_s.rjust(5)} #{workspace_project.name}"
        end
      end
    end

    def workspaces
      data = http_get("https://kanbanery.com/api/v1/user/workspaces.json/")
      data.collect do |workspace_data|
        projects = workspace_data["projects"].collect { |workspace_project| OpenStruct.new(id: workspace_project["id"], name: workspace_project["name"]) }
        OpenStruct.new(id: workspace_data["id"], name: workspace_data["name"], projects: projects)
      end
    end

    def project_tasks(workspace_name, project_id)
      data = http_get("https://#{workspace_name}.kanbanery.com/api/v1/projects/#{project_id}/tasks.json")
      data.keep_if { |d| d.has_key?("owner_id") && d["owner_id"] == own_user_id }
      data
    end

    def own_user_id
      @own_user_id ||=
        begin
          data = http_get("https://avarteq.kanbanery.com/api/v1/user.json")
          data["id"]
        end
    end

    private

    def http_get(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)
      request['X-Kanbanery-ApiToken'] = BaneryStats.api_token or raise "You must set BaneryStats.api_token to your API token"

      response = http.request(request)

      data = ActiveSupport::JSON.decode(response.body)
    end
  end
end

BaneryStats.api_token = ENV['KANBANERY_API_TOKEN']

BaneryStats::OutputSummary.run
