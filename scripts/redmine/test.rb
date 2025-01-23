require 'net/http'
require 'json'
require 'logger'

log_file = './logs/redmine_update.log'
logger = Logger.new(log_file)
logger.level = Logger::WARN

redmine_url = ENV['REDMINE_URL_BASE']
api_token = ENV['API_TOKEN_COMMON']
parent_id = ENV['PARENT_ID']

def get_ticket_info(redmine_url, api_token, issue_id, logger)
    uri = URI("#{redmine_url}/common/issues/#{issue_id}.json")
    logger.debug("Fetching issue ##{issue_id} from: #{uri}")
    request = Net::HTTP::Get.new(uri)
    request['X-Redmine-API-Key'] = api_token
    request['Content-Type'] = 'application/json'
  
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
        json_data = JSON.parse(response.body)
        issue = json_data['issue']
    else
        logger.error("Failed to fetch issue ##{issue_id}: #{response.code} #{response.message}")
    end

    return issue
end

def update_ticket_tag(redmine_url, api_token, issue_id, tags, logger)
    uri = URI("#{redmine_url}/common/issues/#{issue_id}.json?include=tags")
    logger.debug("Updating issue ##{issue_id} at: #{uri}")
    request = Net::HTTP::Put.new(uri)
    request['X-Redmine-API-Key'] = api_token
    request['Content-Type'] = 'application/json'
    
    request.body = { issue: { "tag_list": tags } }.to_json
  
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
  
    if response.is_a?(Net::HTTPSuccess)
      logger.info("Updated issue ##{issue_id}")
    else
      logger.error("Failed to update issue ##{issue_id}: #{response.code} #{response.message}")
    end
end

def filter_and_validate_tags(tags, logger)
    # Please add this delete_tags list, if you want to remove the tag.
    delete_tags = []
    check_remove_tags = []
    resutl_tags = []

    tags.each do |tag|
        if !delete_tags.include?(tag)
            resutl_tags.push(tag)
        else
            check_remove_tags.push(tag)
        end
    end

    if check_remove_tags.length > 0
        for delete_tag in check_remove_tags do
            if !delete_tags.include?(delete_tag)
                raise "Error: #{delete_tags} != #{check_remove_tags}"
            end
        end
    end

    logger.warn("Remove tags: #{check_remove_tags}")
    return resutl_tags
end


# List of issue IDs to process
issue_ids = []  

issue_ids.each do |issue_id|
    logger.warn("Processing issue ID: #{issue_id}")

    logger.info("Fetching issue info...")
    issue = get_ticket_info(redmine_url, api_token, number, logger)
    subject = issue['subject']
    logger.warn("Current ID: #{number}")
    logger.warn("Current subject: #{subject}")
    tags = issue['tags']
    tags_name = tags.map { |tag| tag['name'] }
    logger.warn("Current tags: #{tags_name}")
    tags_list = filter_and_validate_tags(tags_name, logger)
    logger.warn("New tags: #{tags_list}")
    puts "Start Update Ticket Tag"
    update_ticket_tag(redmine_url, api_token, number, tags_list, logger)
    puts "End Update Ticket Tag"
    issue = get_ticket_info(redmine_url, api_token, number, logger)
    logger.warn(issue['tags'])
end
