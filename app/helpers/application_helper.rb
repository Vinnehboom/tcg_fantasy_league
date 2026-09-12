module ApplicationHelper

  def flash_key_mapping(key)
    {
      notice: 'success',
      alert: 'warning',
      error: 'danger'
    }[key.to_sym]
  end

  def player_name_link(player, html_options = {})
    return player.display_name if player.suppressed?

    link_to(player.display_name, player.external_url, **html_options.reverse_merge(target: '_blank'))
  end

end
