class CreateBoxScores < ActiveRecord::Migration
  def change
    create_table :box_scores do |t|
      t.integer :gid_espn
      t.string :status
      t.date :date
      t.timestamps
    end
    add_index :box_scores, :gid_espn, :name => "gid_espn_ix", :unique => true
    add_index :box_scores, :date,     :name => "date_ix"
  end
end
