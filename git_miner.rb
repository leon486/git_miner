require "rubygems"
require "sequel"

#Script to collect data from GITrepositiories

DB = Sequel.connect(:adapter => 'mysql2',:user => 'researcher', :password => "b3SxvkYbGJKe", :host => "127.0.0.1", :port=> "8889" , :database => "quality_ratings")

#FUNCTIONS
######
#1
def write_commit_history_to_file repo
  system('git --git-dir repos/'+repo[:folder]+'/.git --work-tree=repos/'+repo[:folder]+'/ log --pretty=tformat:"%H|||%ai|||%an|||%s|||" > commits/'+repo[:filename]+'.txt')
  #Use %b to get the body 
end 

#2
def read_commits repo
  counter = 1
  file = File.new("commits/"+repo[:filename]+".txt", "r")
    while (line = file.gets)
      #Break line in blocks to obtain data
      puts "#{counter}: #{line}"
      data = line.split('|||')
      commit_date = DateTime.strptime(data[1], "%F %T %z")
      # => 0  hash
      # => 2  user
      # => 3  title

      DB[:commit].insert('',repo[:id],'',data[0],'','','',data[2],commit_date,commit_date,data[3],'')
      counter= counter+1
    end
    file.close
end

#3  
def find_bug_commits repo
  commits = DB[:commit].where(:repository_id=>repo[:id])
  commits.each do |c|
    bug = false
    #Get the body of the commit
    commit_body = `git --git-dir repos/#{repo[:folder]}/.git show --pretty="format:%b" --no-patch #{c[:hash]}`
  
    #find bugs
    bug_keywords = ['bug', 'error', 'issue','fix','bugfix']
    bug_keywords.each do |bk|
      if (commit_body.downcase.include? bk)
        bug = true
      end
      if (c[:title].downcase.include? bk)
        bug = true
      end
    end
    commits.where(:id=>c[:id]).update(:body => commit_body,:bug =>bug)
  end
end

#4    
def calculate_churn repo
  commits = DB[:commit].where(:repository_id=>repo[:id])
  commits.each do |c|
    #Calculate churn
    comm = `git --git-dir repos/#{repo[:folder]}/.git --work-tree=repos/#{repo[:folder]}// show --stat #{c[:hash]} > churn.txt`
    last_line = `tail -n 1 churn.txt`
    
    modifications = last_line.split(',')
    churn = 0
    
    modifications.each do |m|
      if m.include? '(-)'
        delitions = m.split(' ')
        churn = delitions[0]
      end
    end
    commits.where(:id=>c[:id]).update(:churn => churn)
  end
end
  
#5
def calculate_loc repo
#  commits = DB[:commit].where(:repository_id=>repo[:id])
  commits = DB[:commit].where(:repository_id=>repo[:id],:loc=>0)
  if commits.count > 0
    commits.each do |c|
      #Calculate loc
      loc=0
    
      p '--Checking out commit--'
      system("git --git-dir=repos/#{repo[:folder]}/.git --work-tree=repos/#{repo[:folder]}/ checkout -f #{c[:hash]}")

      p "--Calculating sloc for commit #{c[:id]}--"
    
      #Calculate using sloccount
      loc_raw = `sloccount repos/#{repo[:folder]}/`
      sloc_start = loc_raw.index('(SLOC)')
      loc_raw = loc_raw[sloc_start..loc_raw.length]
      loc_raw = loc_raw.split('=')
      loc_raw = loc_raw[1].split('Development')
      loc = loc_raw[0].strip.gsub(",","")

=begin
      #Calculate loc using cloc 
      loc_raw = `cloc repos/#{repo[:folder]}/`
      sloc_start = loc_raw.index('SUM:')
      loc_raw = loc_raw[sloc_start..loc_raw.length]
      loc_raw = loc_raw.split(' ')    
      loc =  loc_raw[4]
=end
    
      p "--Updating DB for commit #{c[:id]}--"
      commits.where(:id=>c[:id]).update(:loc => loc.to_i)

    end
      system("git --git-dir=repos/#{repo[:folder]}/.git --work-tree=repos/#{repo[:folder]}/ checkout -f master")
  end
end

######


repositories = DB[:repository].where(:active=>1,:completed=>0)
repositories.each do |r|
  p "Working on repository #{r[:name]}::::"
  if !r[:file_completed]
    p "Generating commit file"
    write_commit_history_to_file r
      r[:file_completed] = 1
      repositories.where(:id=>r[:id]).update(:file_completed => 1)
  else
    p "File already recreated, skipping file creation"
  end

  if !r[:commits_completed]
    p "Extracting commits"
    read_commits r
      r[:commits_completed] = 1
      repositories.where(:id=>r[:id]).update(:commits_completed => 1)
  else
    p "Commit already extracted, skipping commit extraction"
  end

  if !r[:bug_completed]
    p "Detecting bug commits"
    find_bug_commits r
      r[:bug_completed] = 1
      repositories.where(:id=>r[:id]).update(:bug_completed => 1)
  else
    p "Bugs already detected, skipping bug detection"
  end

  if !r[:churn_completed]
    p "Calculating Churn"
    calculate_churn r
      r[:churn_completed] = 1
      repositories.where(:id=>r[:id]).update(:churn_completed => 1)
  else
    p "Churn already calculated, skipping churn calculation"
  end

  if !r[:loc_completed]
    p "Calculating SLOC"
    calculate_loc r
      r[:loc_completed] = 1
      repositories.where(:id=>r[:id]).update(:loc_completed => 1)
  else
    p "SLOC already calculated, skipping SLOC calculation"
  end

  if(r[:file_completed] && r[:commits_completed] && r[:bug_completed] && r[:churn_completed] && r[:loc_completed])
      repositories.where(:id=>r[:id]).update(:completed => 1)
  end
end

