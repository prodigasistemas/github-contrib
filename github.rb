require 'multi_json'
require 'open-uri'
require 'date'
require 'csv'

class Github
  attr_accessor :token, :user_login, :user_name, :repositories, :csv_file

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
    @csv_file = "./#{@user_login}_github_contributions.csv"

    File.delete(@csv_file) if File.exist?(@csv_file)

    puts "> Login: #{user_login}"
    puts "> Name: #{user_name}"
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
        @repositories << repo['full_name']
      end

      page += 1
    end

  end

  def get_commits
    total_size = @repositories.size

    @repositories.each_with_index do |repo, index|
      puts "> #{index + 1}/#{total_size} - Getting commits the #{repo} repository ..."

      page = 1
      contributions = []

      while true do
        begin
          commits = MultiJson.load(
            open("https://api.github.com/repos/#{repo}/commits?author=#{@user_login}&page=#{page}",
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
          else
            puts "ERROR: #{reason}"
            exit
          end
        end
      end

      if contributions.size > 0
        puts "= #{contributions.size} contributions"

        CSV.open(@csv_file, "a") do |csv|
          contributions.each do |line|
            csv << [repo, line[:date], line[:message]]
          end
        end
      end
    end

    puts "> Done!"
  end
end
