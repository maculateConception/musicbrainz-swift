import Cocoa

///
/// View controller for the main view.
///
class ViewController: NSViewController {
    
    ///
    /// The text field in which the user types in the name of an artist.
    ///
    @IBOutlet weak var txtArtist: NSTextField!
    
    ///
    /// The text field in which the user types in the name of an album or a track title.
    ///
    @IBOutlet weak var txtRelease: NSTextField!
    
    ///
    /// A label that shows the status of a search. eg. "Searching ..." or "Found cover art",
    /// and/or any input validation errors.
    ///
    @IBOutlet weak var lblStatus: NSTextField!
    
    ///
    /// A label that shows the status of a search. eg. "Searching ..." or "Found cover art"
    ///
    @IBOutlet weak var coverArtView: NSImageView!
    
    ///
    /// The utilitty that performs Music Brainz searches and retrieves cover art.
    ///
    private lazy var musicBrainzClient = MBRESTClient()
    
    ///
    /// A default image to show when a search failed to retrieve any cover art.
    ///
    private lazy var imgNotFound = NSImage(named: "NotFound")!
    
    override func viewDidAppear() {
        
        // Set focus on the artist text field, when the view first shows up.
        view.window?.makeFirstResponder(txtArtist)
    }
    
    @IBAction func searchAction(_ sender: NSButton) {
        
        // Remove any leading/trailing whitespace from the input fields.
        let artist = txtArtist.stringValue.trim()
        let release = txtRelease.stringValue.trim()
        
        // Validate the input (cannot be empty).
        if artist.isEmpty || release.isEmpty {
            
            // Inform the user of the invalid input.
            lblStatus.stringValue = "Please enter both artist and album / title !"
            return
            
        } else {
            
            // Inform the user that the search is ongoing.
            self.lblStatus.stringValue = "Searching for cover art ... please wait."
        }
        
        // Perform the search asynchronously on a background thread, so as not to block the main thread.
        DispatchQueue.global(qos: .userInteractive).async {
            
            do {
                
                // Perform the search using the client object.
                let coverArt = try self.musicBrainzClient.getCoverArt(forArtist: artist, andReleaseTitle: release)

                // Update the UI with the search results (on the main thread).
                DispatchQueue.main.async {
                    
                    // If cover art was found, display it in the image view. Otherwise, show a default image.
                    self.coverArtView.image = coverArt != nil ? coverArt : self.imgNotFound
                    
                    // Update the staus label with an informative message.
                    self.lblStatus.stringValue = coverArt != nil ? "Found cover art !" : "Sorry, no cover art was found."
                }
                
            } catch {
                
                // Update the UI with information about the error (on the main thread).
                DispatchQueue.main.async {
                    
                    // Update the staus label with an informative message.
                    if let httpError = error as? HTTPError {
                        self.lblStatus.stringValue = "Sorry, an HTTP error occurred: \(httpError.description) (code: \(httpError.code)"
                    } else {
                        self.lblStatus.stringValue = "Sorry, an error occurred: \(error)"
                    }
                }
            }
        }
    }
}

extension String {

    ///
    /// Convenience function for trimming leading / trailing whitespace from a String.
    ///
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
