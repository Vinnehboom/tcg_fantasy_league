module BootstrapIconHelper

  def bootstrap_icon(icon_name, classes: '')
    render partial: 'shared/bootstrap_icon_helper', locals: { icon_name:, classes: }
  end

end
