## Example usage of CsvScriptToPdf
## Attach this to any Node and run to test

extends Node

func _ready() -> void:
	test_pdf_generation()


func test_pdf_generation() -> void:
	var converter := CsvScriptToPdf.new()
	
	# Example gameplay script CSV
	var csv_data := """Scene,Character,Dialogue,Action,Notes
1,NARRATOR,"The ancient ruins loom ahead, shrouded in mist.",Fade in from black,Opening cinematic
1,HERO,"Finally... after all these years.",Walks forward slowly,Determined expression
1,COMPANION,"Are you sure about this? The legends say no one returns.",Grabs Hero's arm,Worried tone
2,HERO,"I have to know the truth about my father.",Pulls away gently,Resolute
2,COMPANION,"Then I'm coming with you.",Steps forward,Loyal determination
3,NARRATOR,"Together they enter the forgotten temple.",Camera pans up,Transition to gameplay
3,ANCIENT_VOICE,"WHO DARES DISTURB MY SLUMBER?",Echo effect,Boss intro
4,HERO,"We seek only answers!",Battle stance,Combat begins
4,COMPANION,"Watch out!",Pushes Hero aside,Quick time event
5,BOSS,"YOUR FATHER KNEW THE PRICE OF KNOWLEDGE.",Attacks,Phase 1 begins
5,HERO,"What do you mean?!",Dodges,Player choice coming
6,BOSS,"HE TRADED HIS SOUL FOR FORBIDDEN POWER.",Slams ground,Shockwave attack
6,COMPANION,"Don't listen to it!",Healing spell,Support action
7,HERO,"Then I'll finish what he started.",Power up,Cinematic moment
7,NARRATOR,"The final battle begins.",Music swells,Phase 2 transition"""

	var title := "The Forgotten Temple"
	var summary := "Act 1: Discovery - This script covers the opening cinematic and first boss encounter. The hero and companion enter the ancient ruins seeking answers about the hero's father, only to awaken a powerful guardian. This document contains all dialogue, stage directions, and technical notes for the development team."
	
	# Generate the PDF
	print("Generating PDF...")
	var result := converter.CsvScriptToPDF(title, summary, csv_data, "user://gameplay_script.pdf")
	
	if result == OK:
		print("✓ PDF created successfully!")
		print("  Saved to: user://gameplay_script.pdf")
		print("  Full path: ", ProjectSettings.globalize_path("user://gameplay_script.pdf"))
	else:
		print("✗ Failed to create PDF, error code: ", result)
