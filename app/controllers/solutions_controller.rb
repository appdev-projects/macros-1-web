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
    chat.system("You are an expert nutritionist. The user will provide either a photo, a description, or both of one or more food items. Your job is to identify the food items and estimate how many grams of carbohydrates, grams of protein, grams of fat, and total calories are in a meal. You should also add a breakdown of how you arrived at these figures, and any other notes you have. You can search the web.")
    chat.schema = '{
      "name": "meal_nutrition_estimate",
      "schema": {
        "type": "object",
        "properties": {
          "rationale": {
            "type": "string",
            "description": "Explanation of how you came to the estimates for the nutritional values of the items and totals."
          },
          "items": {
            "type": "array",
            "description": "List of food items with their corresponding macronutrient and calorie values.",
            "items": {
              "type": "object",
              "properties": {
                "description": {
                  "type": "string",
                  "description": "Description or name of the food item."
                },
                "grams_of_carbs": {
                  "type": "integer",
                  "description": "Amount of carbohydrates in grams."
                },
                "grams_of_fat": {
                  "type": "integer",
                  "description": "Amount of fat in grams."
                },
                "grams_of_protein": {
                  "type": "integer",
                  "description": "Amount of protein in grams."
                },
                "calories": {
                  "type": "integer",
                  "description": "Total calories contained in the item."
                }
              },
              "required": [
                "description",
                "grams_of_carbs",
                "grams_of_fat",
                "grams_of_protein",
                "calories"
              ],
              "additionalProperties": false
            }
          },
          "total_grams_of_carbs": {
            "type": "integer",
            "description": "Total grams of carbohydrates for all items."
          },
          "total_grams_of_fat": {
            "type": "integer",
            "description": "Total grams of fat for all items."
          },
          "total_grams_of_protein": {
            "type": "integer",
            "description": "Total grams of protein for all items."
          },
          "total_calories": {
            "type": "integer",
            "description": "Total calories for all items."
          }
        },
        "required": [
          "rationale",
          "items",
          "total_grams_of_carbs",
          "total_grams_of_fat",
          "total_grams_of_protein",
          "total_calories"
        ],
        "additionalProperties": false
      },
      "strict": true
    }'


    if @the_image.blank? && @the_description.blank?
      @rationale = "You must provide at least one of image or description."
    else
      if @the_image.present?
        chat.user("Here's an image of the meal:", image: @the_image)
      end

      if @the_description.present?
        chat.user(@the_description)
      end

      result = chat.generate!

      ap result

      @list_of_items = result.fetch(:items)
      @g_carbs = result.fetch(:total_grams_of_carbs)
      @g_protein = result.fetch(:total_grams_of_protein)
      @g_fat = result.fetch(:total_grams_of_fat)
      @kcal = result.fetch(:total_calories)
      @rationale = result.fetch(:rationale)
    end

    if @the_image.present?
      @the_image_data_uri = DataURI.convert(@the_image)
    end

    render({ :template => "solution_templates/results" })
  end

end
