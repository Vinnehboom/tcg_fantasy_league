class Season < ApplicationRecord

  belongs_to :game

  validates :label, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date
  validate :no_overlapping_range_for_game

  scope :covering, ->(date) { where(start_date: ..date).where(end_date: date..) }

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank? || end_date >= start_date

    errors.add(:end_date, :before_start_date)
  end

  def no_overlapping_range_for_game
    return if game_id.blank? || start_date.blank? || end_date.blank?

    overlapping = Season.where(game_id:).where.not(id:).where(start_date: ..end_date).where(end_date: start_date..)
    errors.add(:start_date, :overlapping_season) if overlapping.exists?
  end

end
