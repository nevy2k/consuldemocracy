class AddDatesToProposal < ActiveRecord::Migration[6.1]
  def change
    add_column :proposals, :starts_at, :datetime
    add_column :proposals, :ends_at, :datetime
    add_column :proposals, :location, :string
    add_column :proposals, :status, :integer, default: 0
    add_column :proposals, :team_members, :integer
  end
end
