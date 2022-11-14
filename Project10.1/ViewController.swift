//
//  ViewController.swift
//  Project10.1
//
//  Created by Maks Vogtman on 21/09/2022.
//

import UIKit

// UIImagePickerControllerDelegate is telling us when the user either selected a picture or cancelled the picker.
class ViewController: UICollectionViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var people = [Person]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPerson))
        
        
// Finally, we need to load the array back from disk when the app runs.
        
// This code is effectively the save() method in reverse: we use the object(forKey:) method to pull out an optional Data, using if let and as? to unwrap it. We then give that to an instance of JSONDecoder to convert it back to an object graph – i.e., our array of Person objects.
        let defaults = UserDefaults.standard
        
        if let savedPeople = defaults.object(forKey: "people") as? Data {
            let jsonDecoder = JSONDecoder()
            
    // Once again, note the interesting syntax for decode() method: its first parameter is [Person].self, which is Swift’s way of saying “attempt to create an array of Person objects.” This is why we don’t need a typecast when assigning to people – that method will automatically return [People], or if the conversion fails then the catch block will be executed instead.
            do {
                people = try jsonDecoder.decode([Person].self, from: savedPeople)
            } catch {
                print("Failed to load people.")
            }
        }
    }

// This must return an integer, and tells the collection view how many items you want to show in its grid.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people.count
    }
    
    
// This must return an object of type UICollectionViewCell. We already designed a prototype in Interface Builder, and configured the PersonCell class for it, so we need to create and return one of these.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
// We need to add a conditional typecast to sent back our custom PersonCell type, because we'll soon want to access its imageView and name outlets.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
            
        // Calling this method will unconditionally make your app crash – it will die immediately, and print out any message you provide to it.
            fatalError("Unable to dequeue a PersonCell")
        }
        
        // We used indexPath.item, because collection views don’t really think in terms of rows.
        let person = people[indexPath.item]
        
        cell.name.text = person.name
        
        let path = getDocumentsDirectory().appendingPathExtension(person.image)
        cell.imageView.image = UIImage(contentsOfFile: path.path)
        
        // UIColor initializer: UIColor(white:alpha:) is useful when you only want grayscale colors.
        cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.cornerRadius = 3
        
        // That code sets the cornerRadius property, which rounds the corners of a CALayer – or in our case the UIView being drawn by the CALayer.
        cell.layer.cornerRadius = 7
        
        return cell
    }
    
    
    // This method is where we need to use the UIImagePickerController
    @objc func addNewPerson() {
        let picker = UIImagePickerController()
        
        // allowsEditing property = true, allows the user to crop (przyciąć) the picture they select.
        picker.allowsEditing = true
        
        // When you set self as the delegate, you'll need to conform not only to the UIImagePickerControllerDelegate protocol, but also the UINavigationControllerDelegate protocol.
        picker.delegate = self
        present(picker, animated: true)
    }
    
    
// This delegate method which returns when the user selected an image and it's being returned to you. This method needs to do several things:
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Extract the image from the dictionary that is passed as a parameter.
        guard let image = info[.editedImage] as? UIImage else { return }
        
        // Generate a unique filename for it.
        // This is so that we can copy it to our app's space on the disk without overwriting anything, and if the user ever deletes the picture from their photo library we still have our copy.
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        // Convert it to a JPEG, then write that JPEG to disk.
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            // Writing information to disk is easy enough, but finding where to put it is tricky.
            try? jpegData.write(to: imagePath)
        }
        
        // Every time a picture is imported, we can create a Person object for it and add it to an array to be shown in the collection view.
        let person = Person(name: "Unknown", image: imageName)
        people.append(person)
        save()
        collectionView.reloadData()
        
        // Dismiss the view controller.
        dismiss(animated: true)
    }
    

// All apps that are installed have a directory called Documents where you can save private information for the app, and it's also automatically synchronized with iCloud. The problem is, it's not obvious how to find that directory, this method does exactly that.
    func getDocumentsDirectory() -> URL {
        // The first parameter of FileManager.default.urls asks for the documents directory, second parameter adds that we want the path to be relative to the user's home directory.
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        // This returns an array that nearly always contains only one thing: the user's documents directory.
        return path[0]
    }
    
    
    // This delegate method is triggered when the user taps a cell.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // This method needs to pull out the Person object at the array index that was tapped.
        let person = people[indexPath.item]
        
        // Then show a UIAlertController asking users to rename the person.
        let ac = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
        // Adding a text field to an alert controller is done with the addTextField() method.
        ac.addTextField()
        
        // One action to save the change. To save the changes, we need to add a closure that pulls out the text field value and assigns it to the person's name property, then we'll also need to reload the collection view to reflect the change.
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
            guard let newName = ac?.textFields?[0].text else { return }
            person.name = newName
            self?.save()
            self?.collectionView.reloadData()
        })
        // One action to cancel the alert.
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    
// As with NSCoding we’re going to create a single save() method we can use anywhere that's needed. This time it’s going to use the JSONEncoder class to convert our people array into a Data object, which can then be saved to UserDefaults. This conversion might fail, so we’re going to use if let and try? so that we save data only when the JSON conversion was successful.
    func save() {
        let jsonEncoder = JSONEncoder()
        
        if let savedData = try? jsonEncoder.encode(people) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "people")
        } else {
            print("Failed to save people.")
        }
    }
}

