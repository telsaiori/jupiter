# == Schema Information
#
# Table name: records
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  project_id  :integer
#  minutes     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  data        :hstore
#  record_type :integer
#  todo_id     :integer
#

class Search::Record < ::Record

  CREATED_AT_PERIODS = [:this_week, :last_week, :this_month, :last_month].freeze
  GROUPS = [:day, :week, :month, :record_type, :user, :project].freeze

  class << self
    def ransackable_scopes(_auth_object = nil)
      [:record_type_key_in, :created_at_period_is, :group_by]
    end

    def record_type_key_in(*values)
      values = values.select(&:present?).map { |v| record_types[v.to_sym] }
      where(record_type: values)
    end

    def created_at_period_is(period)
      case period.to_sym
      when :this_week then this_week
      when :last_week then last_week
      when :this_month then this_month
      when :last_month then last_month
      end
    end

    def group_by(group)
      scoped = select("SUM(minutes) as minutes")
      case group.to_sym
      when :record_type then scoped.select(:record_type).group(:record_type).reorder(:record_type)
      when :user        then scoped.select(:user_id).group(:user_id).reorder("minutes")
      when :project     then scoped.select(:project_id).group(:project_id).reorder("minutes")
      when :day         then scoped.select("date(created_at) as time_text").group(:time_text).reorder("time_text")
      when :week        then scoped.select("EXTRACT(YEAR FROM created_at)::text ||  EXTRACT(WEEK FROM created_at)::text AS time_text, max(created_at) as max_time").group(:time_text).reorder("max_time")
      when :month       then scoped.select("EXTRACT(YEAR FROM created_at)::text ||  EXTRACT(MONTH FROM created_at)::text AS time_text, max(created_at) as max_time").group(:time_text).reorder("max_time")
      end
    end

    def created_at_collection
      CREATED_AT_PERIODS.map { |key| [I18n.t("models.record.created_at_periods.#{key}"), key] }
    end

    def group_collection
      GROUPS.map { |key| [I18n.t("models.record.groups.#{key}"), key] }
    end
  end
end
