class Job
  include MongoMapper::Document

  set_collection_name "drqueue_jobs"

  key :name, String
  key :startframe, Integer
  key :endframe, Integer
  key :blocksize, Integer
  key :renderer, String
  key :scenefile, String
  key :retries, Integer
  key :owner, String
  key :created_with, String

end