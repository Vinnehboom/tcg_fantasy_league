class ActiveRecord::Base

  def self.contains(column_name, search_string)
    where("lower(#{column_name}) ilike ?", "%#{search_string.to_s.downcase}%")
  end
  
end