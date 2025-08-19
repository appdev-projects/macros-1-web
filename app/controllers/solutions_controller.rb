class SolutionsController < ApplicationController

  def display_form
    render({ :template => "solution_templates/new_form" })
  end

  def process_inputs
    @the_image = params.fetch("image_param", "")
    @the_description = params.fetch("description_param", "")

    chat = AI::Chat.new
    chat.model = "o3"
    chat.reasoning_effort = :high
    chat.web_search = true
    chat.system("You are an expert nutritionist. Your job is to estimate how many grams of carbohydrates, grams of protein, grams of fat, and total calories are in a meal. You should also add a breakdown of how you arrived at these figures, and any other notes you have. The user will provide either a photo, a description, or both.")
    chat.schema = '{
      "name": "nutrition_info",
      "schema": {
        "type": "object",
        "properties": {
          "carbohydrates": {
            "type": "number",
            "description": "Amount of carbohydrates in grams."
          },
          "protein": {
            "type": "number",
            "description": "Amount of protein in grams."
          },
          "fat": {
            "type": "number",
            "description": "Amount of fat in grams."
          },
          "total_calories": {
            "type": "number",
            "description": "Total calories in kcal."
          },
          "notes": {
            "type": "string",
            "description": "A breakdown of how you arrived at the values, and additional notes."
          }
        },
        "required": [
          "carbohydrates",
          "protein",
          "fat",
          "total_calories",
          "notes"
        ],
        "additionalProperties": false
      },
      "strict": true
    }'

    if @the_image.blank? && @the_description.blank?
      @notes = "You must provide at least one of image or description."
    else
      if @the_image.present?
        chat.user("Here's an image of the meal:", image: @the_image)
      end

      if @the_description.present?
        chat.user(@the_description)
      end

      result = chat.generate!

      ap result

      @g_carbs = result.fetch(:carbohydrates)
      @g_protein = result.fetch(:protein)
      @g_fat = result.fetch(:fat)
      @kcal = result.fetch(:total_calories)
      @notes = result.fetch(:notes)
    end

    if @the_image.present?
      @the_image_data_uri = DataURI.convert(@the_image)
    end

    render({ :template => "solution_templates/results" })
  end

end
