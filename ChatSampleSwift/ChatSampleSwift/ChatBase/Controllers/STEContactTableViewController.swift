//
//  STEContactTableViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 4/3/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STEContactTableViewController: UITableViewController {
    
    let contactManager = STEContactManager.shared
    var searchController: UISearchController!
    var searchItem: UIBarButtonItem!
    var exitItem: UIBarButtonItem!
    
    var searchingDatas = [STEVCard]()
    var isSearching = false
    
    lazy var noContactView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 64 - 50 - 44))
        let lbContent = UILabel(frame: CGRect(x: 10, y: (SCREEN_HEIGHT - 55 - 64) * 0.5, width: SCREEN_WIDTH - 20, height: 50))
        lbContent.numberOfLines = 1
        lbContent.font = UIFont.boldSystemFont(ofSize: 25)
        lbContent.textAlignment = .center
        lbContent.textColor = UIColor.lightGray
        lbContent.text = "Không có kết quả."
        view.addSubview(lbContent)
        return view
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Contact"
        searchItem = UIBarButtonItem(image: UIImage(named: "search_icon"), style: .plain, target: self, action: #selector(STEContactTableViewController.searchTapped))
        exitItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(STEContactTableViewController.exitTapped))
        navigationItem.rightBarButtonItem = searchItem
        navigationItem.leftBarButtonItem = exitItem

        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "STEContactTableViewCell", bundle: nil), forCellReuseIdentifier: STEContactTableViewCell.identifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "STEHeaderView")
        
        NotificationCenter.default.addObserver(self, selector: #selector(STEContactTableViewController.handleLocalContactLoaded(notification:)), name: Notification.Name.STELocalContactLoadedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEContactTableViewController.handleDetailContactFinish(notification:)), name: Notification.Name.STEDidTapAddContactNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEContactTableViewController.handleDetailContactFinish(notification:)), name: Notification.Name.STEDidTapSendContactNotification, object: nil)
        
        configureSearchController()
        
        if !contactManager.loadedLocalContact {
            STEShowProgress(description: nil, inView: self.view)
            contactManager.getLocalContacts()
        } else {
            self.checkReloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if searchController.isActive {
            searchController.searchBar.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if searchController.searchBar.isFirstResponder {
            searchController.searchBar.resignFirstResponder()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : contactManager.localKeys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return searchingDatas.count
        }
        
        if let key = contactManager.localKeys[safe: section], let rows = contactManager.localSections[key] {
            return rows.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: STEContactTableViewCell.identifier, for: indexPath) as! STEContactTableViewCell
        if let contact = getLocalContact(indexPath: indexPath) {
            cell.present(contact: contact)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return STEContactTableViewCell.defaultHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isSearching ? 0 : 20
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "STEHeaderView")
        headerView?.textLabel?.text = contactManager.localKeys[section]
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let contact = self.getLocalContact(indexPath: indexPath) {
            let detailVC = STEDetailContactTableViewController.init(contact: contact, mode: .send)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return isSearching ? nil : contactManager.localKeys
    }
    
    // MARK: - Utils

    @objc private func exitTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func searchTapped() {
        showSearchbar()
    }

    @objc private func handleLocalContactLoaded(notification: Notification) {
        DispatchQueue.main.async {
            STEHideProgress(ofView: self.view)
            self.checkReloadData()
        }
    }
    
    @objc private func handleDetailContactFinish(notification: Notification) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Utils
    
    private func getLocalContact(indexPath: IndexPath) -> STEVCard? {
        if isSearching {
            return searchingDatas[safe: indexPath.row]
        } else {
            if let key = contactManager.localKeys[safe: indexPath.section], let rows = contactManager.localSections[key], let contact = rows[safe: indexPath.row] {
                return contact as? STEVCard
            }
        }
        
        return nil
    }
    
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.searchBar.searchBarStyle = .minimal
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        self.definesPresentationContext = true
    }
    
    private func showSearchbar() {
        navigationItem.setLeftBarButton(nil, animated: true)
        navigationItem.setRightBarButton(nil, animated: true)
        searchController.searchBar.alpha = 0
        isSearching = true
        navigationItem.titleView = searchController.searchBar
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, animations: {
            self.searchController.searchBar.alpha = 1
        }) { (success) in
            self.searchController.searchBar.becomeFirstResponder()
            self.fillContentForSearching()
        }
    }
    
    private func hideSearchbar() {
        searchController.searchBar.resignFirstResponder()
        navigationItem.setLeftBarButton(exitItem, animated: true)
        navigationItem.setRightBarButton(searchItem, animated: true)
        isSearching = false
        UIView.animate(withDuration: 0.3, animations: {
            self.navigationItem.titleView = nil
            self.navigationController?.navigationBar.setNeedsLayout()
            self.navigationController?.navigationBar.layoutIfNeeded()
            self.navigationController?.view.setNeedsLayout()
            self.navigationController?.view.layoutIfNeeded()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }) { (success) in
            
        }
    }
    
    func checkReloadData() {
        STEHideProgress(ofView: self.view)
        DispatchQueue.main.async {
            var shouldShowNoContact = false

            if self.isSearching {
                shouldShowNoContact = self.searchingDatas.count == 0
            } else {
                shouldShowNoContact = self.contactManager.localKeys.count == 0
            }
            
            if (shouldShowNoContact) {
                self.tableView.isScrollEnabled = false
                self.tableView.tableFooterView = self.noContactView
            } else {
                self.tableView.isScrollEnabled = true
                self.tableView.tableFooterView = UIView()
            }
            self.tableView.reloadData()
        }
    }
    
    @objc private func fillContentForSearching() {
        guard let key = searchController.searchBar.text else {
            return
        }
        
        // Xoá dữ liệu cũ
        self.searchingDatas.removeAll()
        STEShowProgress(description: nil, inView: self.view)
        
        let unAccentedKey = key.folding(options: .diacriticInsensitive, locale: .current).capitalized
    
        for key in contactManager.localKeys {
            guard let contacts = contactManager.localSections[key] as? [STEVCard] else {
                continue
            }
            
            for contact in contacts {
                let unAccentedName = contact.name.folding(options: .diacriticInsensitive, locale: .current).capitalized
                let phone = (contact.infos.first?.values.first as? String) ?? ""
                let unAccentedPhone = phone.folding(options: .diacriticInsensitive, locale: .current).capitalized
                
                let nameIsExist = unAccentedName.range(of: unAccentedKey, options: .caseInsensitive)
                let phoneIsExist = unAccentedPhone.range(of: unAccentedKey, options: .caseInsensitive)
                if nameIsExist != nil || phoneIsExist != nil {
                    searchingDatas.append(contact)
                }
            }
        }
        
        STEHideProgress(ofView: self.view)
        self.checkReloadData()
    }
}

// MARK: - Search

extension STEContactTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchbar()
        searchingDatas.removeAll()
        checkReloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(STEContactTableViewController.fillContentForSearching), object: nil)
        perform(#selector(STEContactTableViewController.fillContentForSearching), with: nil, afterDelay: 0.5)
    }
}
