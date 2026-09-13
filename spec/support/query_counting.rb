module QueryCounting

  def count_queries(pattern: nil, &)
    count = 0
    counter = lambda do |*, payload|
      next if payload[:cached] || !payload[:sql].match?(/\A\s*SELECT/i)
      next if pattern && !payload[:sql].match?(pattern)

      count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end

end
