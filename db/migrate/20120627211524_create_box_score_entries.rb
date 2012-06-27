class CreateBoxScoreEntries < ActiveRecord::Migration
  def change
    create_table :box_score_entries do |t|
      t.integer :pid_espn
      t.string  :fname
      t.string  :lname
      t.integer :min
      t.integer :fgm
      t.integer :fga
      t.integer :tpm
      t.integer :tpa
      t.integer :ftm
      t.integer :fta
      t.integer :oreb
      t.integer :reb
      t.integer :ast
      t.integer :stl
      t.integer :blk
      t.integer :to
      t.integer :pf
      t.integer :plusminus
      t.integer :pts
      t.string  :status
      t.integer :box_score_id
      t.timestamps
    end
    add_index :box_score_entries, :pid_espn,     :name => 'pid_espn_ix'
    add_index :box_score_entries, :box_score_id, :name => 'box_score_id_ix'
  end
end
