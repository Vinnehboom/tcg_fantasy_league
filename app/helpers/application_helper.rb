module ApplicationHelper

  def flash_key_mapping(key)
    {
      notice: 'success',
      alert: 'warning',
      error: 'danger'
    }[key.to_sym]
  end

  def player_name_link(player, html_options = {})
    return content_tag(:span, player.display_name) if player.suppressed?

    link_to(player.display_name, player.external_url, **html_options.reverse_merge(target: '_blank'))
  end

  def masked_player_cost(roster_player)
    return '—' if roster_player.player.suppressed?

    roster_player.decorated_player_cost
  end

end
