module ApplicationHelper

  def flash_key_mapping(key)
    {
      notice: 'success',
      alert: 'warning',
      error: 'danger'
    }[key.to_sym]
  end

end
