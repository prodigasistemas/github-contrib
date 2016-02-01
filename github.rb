require 'multi_json'
require 'open-uri'
require 'date'
require 'csv'

class Github
  attr_accessor :token, :user_login, :user_name, :repositories,
    :csv_file_details, :csv_file_summary

  def initialize(token)
    @token = token
  end

  def start
    get_user
    get_repos
    get_commits
  end

  def get_user
    puts "> Getting user data ..."

    begin
      user = MultiJson.load(
        open("https://api.github.com/user",
          "Authorization" => "token #{@token}"
        )
      )
    rescue OpenURI::HTTPError => reason
      puts "ERROR: #{reason}"
      exit
    end

    @user_login = user['login']
    @user_name = user['name']

    puts "> Login: #{user_login}"
    puts "> Name: #{user_name}"

    prepare_csv_files
  end

  def prepare_csv_files
    @csv_file_details = "./#{@user_login}_github_contributions_details.csv"
    @csv_file_summary = "./#{@user_login}_github_contributions_summary.csv"

    File.delete(@csv_file_details) if File.exist?(@csv_file_details)
    File.delete(@csv_file_summary) if File.exist?(@csv_file_summary)

    CSV.open(@csv_file_details, "a") do |csv|
      csv << ["Repository", "Date", "Message"]
    end

    CSV.open(@csv_file_summary, "a") do |csv|
      csv << ["Repository", "Visibility", "Language", "Contributions"]
    end
  end

  def get_repos
    puts "> Getting user repositories ..."

    page = 1
    @repositories = []

    while true do
      begin
        repos = MultiJson.load(
          open("https://api.github.com/user/repos?page=#{page}",
            "Authorization" => "token #{@token}"
          )
        )
      rescue OpenURI::HTTPError => reason
        puts "ERROR: #{reason}"
        exit
      end

      if repos.size == 0
        puts "= #{@repositories.size} repositories"
        break
      end

      repos.each do |repo|
        @repositories << {
          name: repo['full_name'],
          private: (repo['private'] ? 'private' : 'public'),
          fork: repo['fork'],
          language: repo['language']
        }
      end

      page += 1
    end

  end

  def get_commits
    total_size = @repositories.size
    total_contributions = 0

    @repositories.each_with_index do |repo, index|
      puts "> Repository #{index + 1}/#{total_size} - Getting commits the #{repo[:name]} ..."

      page = 1
      contributions = []

      while true do
        begin
          commits = MultiJson.load(
            open("https://api.github.com/repos/#{repo[:name]}/commits?author=#{@user_login}&page=#{page}",
              "Authorization" => "token #{@token}"
            )
          )

          break if commits.size == 0

          commits.each do |commit|
            contributions << {
              date: DateTime.parse(commit['commit']['author']['date']).to_datetime.strftime("%d/%m/%Y %H:%M:%S"),
              message: commit['commit']['message']
            }
          end

          page += 1
        rescue OpenURI::HTTPError => reason
          if reason.to_s.include? "409 Conflict"
            puts "WARNING: repository can be empty"
            break
          elsif reason.to_s.include? "403 Forbidden"
            puts "WARNING: repository unavailable"
            break
          elsif reason.to_s.include? "404 Not Found"
            puts "WARNING: This repository has been disabled"
            break
          else
            puts "ERROR: #{reason}"
            break
          end
        end
      end

      size_contributions = contributions.size
      total_contributions += size_contributions

      if size_contributions > 0
        puts "= #{size_contributions} contributions"

        CSV.open(@csv_file_details, "a") do |csv|
          contributions.each do |line|
            csv << [repo[:name], line[:date], line[:message]]
          end
        end

        CSV.open(@csv_file_summary, "a") do |csv|
          csv << [repo[:name], repo[:private], repo[:language], size_contributions]
        end
      end
    end

    CSV.open(@csv_file_summary, "a") do |csv|
      csv << ["Total", "", "", total_contributions]
    end

    puts "> Done!"
  end
end
