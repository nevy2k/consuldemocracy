class AddDatesToProposal < ActiveRecord::Migration[6.1]
  def change
    add_column :proposals, :starts_at, :datetime
    add_column :proposals, :ends_at, :datetime
    add_column :proposals, :location, :string
  end
end
