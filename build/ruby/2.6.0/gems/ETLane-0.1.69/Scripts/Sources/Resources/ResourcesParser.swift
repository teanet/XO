import ArgumentParser

struct ResourcesParser: ParsableArguments {

	@Option(name: .customLong("output"), help: "Path to output folder")
	var output: String

	@Argument(help: "Google TSV path")
	var tsv: String

	@Option(help: "Download screenshots?")
	var downloadScreenshots = false

	@Option(help: "Figma token")
	var figmaToken: String

	@Option(help: "Figma screenshots page")
	var figmaPage: String?

	@Option(help: "Figma project id")
	var figmaProjectId: String

	@Option(help: "Download preview?")
	var downloadPreview = false
}
