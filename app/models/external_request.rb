class ExternalRequest < ApplicationRecord

  belongs_to :game
  belongs_to :requestable, polymorphic: true, optional: true

  validates :kind, presence: true
  validates :status, presence: true
  validates :started_at, presence: true
  validates :records_processed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  enum kind: { players: 0, tournaments: 1 }
  enum status: { running: 0, success: 1, failure: 2 }

  def duration_seconds
    return nil if finished_at.nil?

    finished_at - started_at
  end

  def mark_success(records_processed:, finished_at: Time.current)
    update!(status: :success, records_processed:, finished_at:)
  end

  def mark_failure(error:, finished_at: Time.current)
    update!(status: :failure, error:, finished_at:)
  end

end
