require "rubygems"
require "sequel"

DB = Sequel.connect(:adapter => 'mysql2',:user => 'researcher', :password => "b3SxvkYbGJKe", :host => "127.0.0.1", :port=> "8889" , :database => "quality_ratings")

repository_id=>9
vs = DB[:version_details].where(:repository_id=>repository_id).order(:details_appDetails_uploadDate_datetime)

vs.each do |v|
  commits = DB[:commit].where(:version_id => nil,:repository_id=>repository_id).where{short_date <= v[:details_appDetails_uploadDate_datetime]}
  commits.update(:version_id => v[:id])
end