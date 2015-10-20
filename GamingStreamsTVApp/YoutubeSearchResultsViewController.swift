//
//  YoutubeSearchResultsViewController.swift
//  GamingStreamsTVApp
//
//  Created by Brendan Kirchner on 10/20/15.
//  Copyright © 2015 Rivus Media Inc. All rights reserved.
//

import UIKit

class YoutubeSearchResultsViewController : LoadingViewController {
    private let LOADING_BUFFER = 20
    private var searchTerm: String!
    private var nextPageToken: String?
    
    override var NUM_COLUMNS: Int {
        get {
            return 5
        }
    }
    
    override var ITEMS_INSETS_X : CGFloat {
        get {
            return 25
        }
    }
    
    override var HEIGHT_RATIO: CGFloat {
        get {
            return 0.75
        }
    }
    
    private var streams = [YoutubeStream]()
    
    convenience init(searchTerm: String){
        self.init(nibName: nil, bundle: nil)
        self.searchTerm = searchTerm
        title = "YouTube"
        YoutubeGaming.setAPIKey("AIzaSyAFLrfWAIk9gdaBbC3h7ymNpAtp9gLiWkY")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        configureViews()
    }
    
    /*
    * viewWillAppear(animated: Bool)
    *
    * Overrides the super function to reload the collection view with fresh data
    *
    */
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.streams.count == 0 {
            loadContent()
        }
    }
    
    func loadContent() {
        self.removeErrorView()
        self.displayLoadingView("Loading Games...")
        
        YoutubeGaming.getStreams(withPageToken: nil, searchTerm: searchTerm) { (streams, nextPageToken, error) -> Void in
            
            guard let streams = streams else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.removeLoadingView()
                    self.displayErrorView("Error loading streams list.\nPlease check your internet connection.")
                })
                return
            }
            
            self.nextPageToken = nextPageToken
            
            self.streams = streams
            dispatch_async(dispatch_get_main_queue(), {
                
                self.removeLoadingView()
                self.collectionView.reloadData()
            })
        }
    }
    
    func configureViews() {
        
        //then do the search bar
        //        self.searchField = UITextField(frame: CGRectZero)
        //        self.searchField.translatesAutoresizingMaskIntoConstraints = false
        //        self.searchField.placeholder = "Search Games"
        //        self.searchField.delegate = self
        //        self.searchField.textAlignment = .Center
        
        let imageView = UIImageView(image: UIImage(named: "youtube"))
        imageView.contentMode = .ScaleAspectFit
        
        super.configureViews("Youtube", centerView: imageView, leftView: nil, rightView: nil)
        
    }
    
    override func loadMore() {
        guard let nextPageToken = self.nextPageToken else {
            return
        }
        self.nextPageToken = nil
        YoutubeGaming.getStreams(withPageToken: nextPageToken, searchTerm: searchTerm) { (streams, nextPageToken, error) -> () in
            self.nextPageToken = nextPageToken
            guard let streams = streams else {
                return
            }
            var paths = [NSIndexPath]()
            
            let filteredStreams = streams.filter({
                let streamId = $0.id
                if let _ = self.streams.indexOf({$0.id == streamId}) {
                    return false
                }
                return true
            })
            
            for i in 0..<filteredStreams.count {
                paths.append(NSIndexPath(forItem: i + self.streams.count, inSection: 0))
            }
            
            self.collectionView.performBatchUpdates({
                self.streams.appendContentsOf(filteredStreams)
                
                self.collectionView.insertItemsAtIndexPaths(paths)
                
                }, completion: nil)
        }
    }
    
    
    override var itemCount: Int {
        get {
            return streams.count
        }
    }
    
    override func getItemAtIndex(index: Int) -> CellItem {
        return streams[index]
    }
}

// MARK - UICollectionViewDelegate interface

extension YoutubeSearchResultsViewController {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let selectedStream = streams[(indexPath.section * NUM_COLUMNS) +  indexPath.row]
        let videoViewController = YoutubeVideoViewController(stream: selectedStream)
        
        self.presentViewController(videoViewController, animated: true, completion: nil)
    }
    
}
