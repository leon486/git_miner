require "rubygems"
require "sequel"

DB = Sequel.connect(:adapter => 'mysql2',:user => 'researcher', :password => "b3SxvkYbGJKe", :host => "127.0.0.1", :port=> "8889" , :database => "quality_ratings")

=begin
#get all repositories
  repo = DB[:repository]
    
  repo.each do |r|
  commits = DB[:commit].where(:repository_id=>r[:id]).order(:short_date)

  last_date = nil
  commits.each do |c|
    c_date = c[:short_date]
    
    if last_date == nil
      days = 0
    else
      days = (c_date - last_date).to_i
    end
    
    com = DB[:commit].where(:repository_id=>r[:id],:id => c[:id])
    com.update(:interval => days)
    last_date = c_date
  end
end
=end
repo = DB[:repository]
  
repo.each do |r|
  vs = DB[:version_details].where(:repository_id=>r[:id]).order(:details_appDetails_uploadDate_datetime)
  vs.each do |v|
    commits = DB[:commit].where(:version_id => v[:id],:repository_id=>r[:id]).order(:short_date)
    commit_count = 0
    total_days = 0
    commits.each do |c|
      if(c[:interval]>0)
        total_days = total_days + c[:interval]
        commit_count = commit_count+1 
      end
    end
    
    avg = (commit_count == 0) ? 0 : total_days/commit_count
    
    ver = DB[:version_details].where(:id=>v[:id])
    ver.update(:avg_commit_days => avg)
  end
end