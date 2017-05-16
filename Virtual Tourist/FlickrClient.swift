//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 05/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation

class FlickrClient {
    
    static let shared = FlickrClient()
    
    // MARK - Search for images
    
    func searchImagesByLatLon(lat latitude: Double, lon longitude: Double, completionHandler: @escaping(_ success: Bool, _ message:  String?, _ data: AnyObject?) -> Void)
    {
        if isValueInRange(latitude, forRange: Constants.Flickr.SearchLatRange) && isValueInRange(longitude, forRange: Constants.Flickr.SearchLonRange) {
            let methodParameters = [
                Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
                Constants.FlickrParameterKeys.BoundingBox: bboxString(lat: latitude, lon: longitude),
                Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
                Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
                Constants.FlickrParameterKeys.Sort: randomSortValue(),
                Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PhotosPerPage
            ]
            _ = searchForImages(methodParameters as [String:AnyObject]) { (data, error) in
                if error != nil {
                    print(error!)
                    completionHandler(false, "Couldn't download new images for that location. Please try later.", nil)
                }
                else{
                    completionHandler(true, nil, data)
                }
            }
        }
        else {
            completionHandler(false, "Lat should be [-90, 90].\nLon should be [-180, 180].", nil)
        }
    }
    
    func randomSortValue() -> String{
        let sortValues = ["date-posted-desc", "date-posted-asc", "date-taken-desc", "date-taken-asc", "interstingness-desc", "interestingness-asc" , "relevance"]
        
        return sortValues[Int(arc4random_uniform(UInt32(sortValues.count)))]
    }

    private func searchForImages(_ methodParameters: [String: AnyObject], completionHandler: @escaping(_ data: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func logErrorAndFinish (_ errorString: String) {
                print(errorString)
                completionHandler(nil, NSError(domain: errorString, code: -1, userInfo: nil))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                logErrorAndFinish("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                logErrorAndFinish("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                logErrorAndFinish("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: AnyObject
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            } catch {
                logErrorAndFinish("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                logErrorAndFinish("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            completionHandler(parsedResult, nil)
        }
        
        // start the task!
        task.resume()
        
        return task
    }
    
    // MARK - Search for one image
    
    func getImage(selectedPhoto photo: Photo, completionHandler: @escaping(_ success: Bool, _ message:  String?, _ data: AnyObject?) -> Void) -> URLSessionDataTask
    {
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: URL(string: photo.url!)!)
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func logErrorAndFinish (_ errorString: String) {
                print(errorString)
                completionHandler(false, errorString, nil)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                logErrorAndFinish("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                logErrorAndFinish("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                logErrorAndFinish("No data was returned by the request!")
                return
            }
            completionHandler(true, nil, data as AnyObject)
        }
        
        // start the task!
        task.resume()
        
        return task
    }
    
    // MARK: Auxiliary methods
    
    private func isValueInRange(_ value: Double,forRange: (Double, Double)) -> Bool {
        return !(value < forRange.0 || value > forRange.1)
    }
    
    private func bboxString(lat latitude: Double, lon longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
