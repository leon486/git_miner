require "rubygems"
require "sequel"

DB = Sequel.connect(:adapter => 'mysql2',:user => 'researcher', :password => "b3SxvkYbGJKe", :host => "127.0.0.1", :port=> "8889" , :database => "quality_ratings")

  repository_id=8
  vs = DB[:version_details].where(:repository_id=>repository_id).order(:details_appDetails_uploadDate_datetime)

  last_version_loc = nil

  vs.each do |v|
    commits = DB[:commit].where(:version_id => v[:id],:repository_id=>repository_id).order(:date)

    p "Version "+v[:id].to_s
    total_churn   = commits.sum(:churn)
    total_commits = commits.count
    bug_commits   = commits.sum(:bug)
    #days
    
      git_users = Hash.new
    if (commits.count > 0)
      last_version_loc = commits.last[:loc]
      
      commits.each do |c|
        u = c[:user]
        if !git_users.has_key? u
          git_users[u] = 0
        end
        git_users[u] = git_users[u]+1
      end
    end
    
    ver = DB[:version_details].where(:repository_id=>repository_id,:id => v[:id])
    ver.update(:loc => last_version_loc)
    ver.update(:total_churn => total_churn)
    ver.update(:commits => total_commits)
    ver.update(:bug_commits => bug_commits)
    ver.update(:number_of_users => git_users.keys.count)

  end