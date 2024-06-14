module ExternalResource

  def external_url
    "#{game.base_uri}#{external_id}"
  end

end
