# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Soft delete support
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # Soft delete method
  def soft_delete
    update(deleted_at: Time.current)
  end

  # Restore soft deleted record
  def restore
    update(deleted_at: nil)
  end

  # Override destroy to implement soft delete by default
  def destroy
    soft_delete
  end

  # Helper to safely serialize model to JSON including associations
  def as_json(options = {})
    super(
      options.reverse_merge(
        except: [:deleted_at, :created_at, :updated_at],
        include: default_includes
      )
    )
  end

  # Placeholder for models to define default associations to include in JSON
  def default_includes
    {}
  end

  # Auditing: track changes before save
  before_save :track_changes

  private

  def track_changes
    if changed?
      # Store a simple audit log in a JSON column (optional, requires audit_logs column)
      if respond_to?(:audit_logs)
        self.audit_logs ||= []
        self.audit_logs << {
          changed_at: Time.current,
          changes: saved_changes.except(:updated_at)
        }
      end
    end
  end
end
