class HelpController < ApplicationController
  def test
    respond_to do |format|
      format.xml { render :xml=>"<ok>true</ok>"}
      format.json { render :json=>"ok" } 
    end
  end
end
