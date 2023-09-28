import Foundation
import Ananda
import AnandaMacros
import SwiftyJSON
import Benchmark

extension SwiftyJSON.JSON {
    nonisolated(unsafe) static let iso8601DateFormatter = ISO8601DateFormatter()

    var urlValue: URL {
        url ?? .init(string: "/")!
    }

    var dateValue: Date {
        Self.iso8601DateFormatter.date(from: stringValue) ?? .init()
    }

    var emptyAsNil: SwiftyJSON.JSON? {
        if type == .dictionary {
            if !dictionaryValue.isEmpty {
                return self
            }
        }

        return nil
    }
}

let naiveJSONData = """
    {
        "name": "Ducky Model Editor",
        "introduction": "I'm Ducky, a document-based app that helps you infer models from JSON.",
        "supported_outputs": [
            "JOSN Schema",
            "Swift",
            "Kotlin",
            "Dart",
            "Go",
            "Proto"
        ],
        "developer": {
            "user_id": 42,
            "username": "nixzhu",
            "email": "zhuhongxu@gmail.com",
            "website_url": "https://nixzhu.dev"
        }
    }
    """.data(using: .utf8)!

let githubEventsJSONData: Data = {
    let url = Bundle.module.url(forResource: "github_events", withExtension: "json")!
    return try! Data(contentsOf: url)
}()

let naiveSuite = BenchmarkSuite(name: "naive")
let githubEventsSuite = BenchmarkSuite(name: "github_events")

naiveSuite.benchmark("Codable decoding") {
    struct IndieApp: Decodable {
        struct Developer: Decodable {
            let userID: Int
            let username: String
            let email: String
            let websiteURL: URL

            private enum CodingKeys: String, CodingKey {
                case userID = "user_id"
                case username
                case email
                case websiteURL = "website_url"
            }
        }

        let name: String
        let introduction: String
        let supportedOutputs: [String]
        let developer: Developer

        private enum CodingKeys: String, CodingKey {
            case name
            case introduction
            case supportedOutputs = "supported_outputs"
            case developer
        }
    }

    let model = try! JSONDecoder().decode(IndieApp.self, from: naiveJSONData)
    assert(model.supportedOutputs[1] == "Swift")
    assert(model.developer.userID == 42)
    assert(model.developer.websiteURL.absoluteString == "https://nixzhu.dev")
}

naiveSuite.benchmark("SwiftyJSON decoding") {
    struct IndieApp {
        struct Developer {
            let userID: Int
            let username: String
            let email: String
            let websiteURL: URL

            init(json: SwiftyJSON.JSON) {
                userID = json["user_id"].intValue
                username = json["username"].stringValue
                email = json["email"].stringValue
                websiteURL = json["website_url"].urlValue
            }
        }

        let name: String
        let introduction: String
        let supportedOutputs: [String]
        let developer: Developer

        init(json: SwiftyJSON.JSON) {
            name = json["name"].stringValue
            introduction = json["introduction"].stringValue
            supportedOutputs = json["supported_outputs"].arrayValue.map { $0.stringValue }
            developer = .init(json: json["developer"])
        }
    }

    let model = try IndieApp(json: SwiftyJSON.JSON(data: naiveJSONData))
    assert(model.supportedOutputs[1] == "Swift")
    assert(model.developer.userID == 42)
    assert(model.developer.websiteURL.absoluteString == "https://nixzhu.dev")
}

naiveSuite.benchmark("Ananda decoding") {
    struct IndieApp: AnandaModel {
        struct Developer: AnandaModel {
            let userID: Int
            let username: String
            let email: String
            let websiteURL: URL

            init(json: AnandaJSON) {
                userID = json.user_id.int()
                username = json.username.string()
                email = json.email.string()
                websiteURL = json.website_url.url()
            }
        }

        let name: String
        let introduction: String
        let supportedOutputs: [String]
        let developer: Developer

        init(json: AnandaJSON) {
            name = json.name.string()
            introduction = json.introduction.string()
            supportedOutputs = json.supported_outputs.array().map { $0.string() }
            developer = .init(json: json.developer)
        }
    }

    let model = IndieApp.decode(from: naiveJSONData)
    assert(model.supportedOutputs[1] == "Swift")
    assert(model.developer.userID == 42)
    assert(model.developer.websiteURL.absoluteString == "https://nixzhu.dev")
}

naiveSuite.benchmark("Ananda decoding with Macro") {
    @AnandaInit
    struct IndieApp: AnandaModel {
        @AnandaInit
        struct Developer: AnandaModel {
            @AnandaKey("user_id")
            let userID: Int
            let username: String
            let email: String
            @AnandaKey("website_url")
            let websiteURL: URL
        }

        let name: String
        let introduction: String
        @AnandaKey("supported_outputs")
        let supportedOutputs: [String]
        let developer: Developer
    }

    let model = IndieApp.decode(from: naiveJSONData)
    assert(model.developer.userID == 42)
}

githubEventsSuite.benchmark("Codable decoding") {
    struct Event: Decodable {
        struct Actor: Decodable {
            let gravatarID: String
            let login: String
            let avatarURL: URL
            let url: URL
            let id: Int

            private enum CodingKeys: String, CodingKey {
                case gravatarID = "gravatar_id"
                case login
                case avatarURL = "avatar_url"
                case url
                case id
            }
        }

        struct Repo: Decodable {
            let url: URL
            let id: Int
            let name: String
        }

        struct Payload: Decodable {
            struct Commit: Decodable {
                struct Author: Decodable {
                    let email: String
                    let name: String
                }

                let url: URL
                let message: String
                let distinct: Bool
                let sha: String
                let author: Author
            }

            struct Forkee: Decodable {
                struct Owner: Decodable {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let organizationsURL: URL
                    let receivedEventsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    private enum CodingKeys: String, CodingKey {
                        case url
                        case gistsURL = "gists_url"
                        case gravatarID = "gravatar_id"
                        case type
                        case avatarURL = "avatar_url"
                        case subscriptionsURL = "subscriptions_url"
                        case organizationsURL = "organizations_url"
                        case receivedEventsURL = "received_events_url"
                        case reposURL = "repos_url"
                        case login
                        case id
                        case starredURL = "starred_url"
                        case eventsURL = "events_url"
                        case followersURL = "followers_url"
                        case followingURL = "following_url"
                    }
                }

                let description: String
                let fork: Bool
                let url: URL
                let language: String
                let stargazersURL: URL
                let cloneURL: URL
                let tagsURL: URL
                let fullName: String
                let mergesURL: URL
                let forks: Int
                let `private`: Bool
                let gitRefsURL: URL
                let archiveURL: URL
                let collaboratorsURL: URL
                let owner: Owner
                let languagesURL: URL
                let treesURL: URL
                let labelsURL: URL
                let htmlURL: URL
                let pushedAt: Date
                let createdAt: Date
                let hasIssues: Bool
                let forksURL: URL
                let branchesURL: URL
                let commitsURL: URL
                let notificationsURL: URL
                let openIssues: Int
                let contentsURL: URL
                let blobsURL: URL
                let issuesURL: URL
                let compareURL: URL
                let issueEventsURL: URL
                let name: String
                let updatedAt: Date
                let statusesURL: URL
                let forksCount: Int
                let assigneesURL: URL
                let sshURL: String
                let `public`: Bool
                let hasWiki: Bool
                let subscribersURL: URL
                let watchersCount: Int
                let id: Int
                let hasDownloads: Bool
                let gitCommitsURL: URL
                let downloadsURL: URL
                let pullsURL: URL
                let homepage: String?
                let issueCommentURL: URL
                let hooksURL: URL
                let subscriptionURL: URL
                let milestonesURL: URL
                let svnURL: URL
                let eventsURL: URL
                let gitTagsURL: URL
                let teamsURL: URL
                let commentsURL: URL
                let openIssuesCount: Int
                let keysURL: URL
                let gitURL: URL
                let contributorsURL: URL
                let size: Int
                let watchers: Int

                private enum CodingKeys: String, CodingKey {
                    case description
                    case fork
                    case url
                    case language
                    case stargazersURL = "stargazers_url"
                    case cloneURL = "clone_url"
                    case tagsURL = "tags_url"
                    case fullName = "full_name"
                    case mergesURL = "merges_url"
                    case forks
                    case `private`
                    case gitRefsURL = "git_refs_url"
                    case archiveURL = "archive_url"
                    case collaboratorsURL = "collaborators_url"
                    case owner
                    case languagesURL = "languages_url"
                    case treesURL = "trees_url"
                    case labelsURL = "labels_url"
                    case htmlURL = "html_url"
                    case pushedAt = "pushed_at"
                    case createdAt = "created_at"
                    case hasIssues = "has_issues"
                    case forksURL = "forks_url"
                    case branchesURL = "branches_url"
                    case commitsURL = "commits_url"
                    case notificationsURL = "notifications_url"
                    case openIssues = "open_issues"
                    case contentsURL = "contents_url"
                    case blobsURL = "blobs_url"
                    case issuesURL = "issues_url"
                    case compareURL = "compare_url"
                    case issueEventsURL = "issue_events_url"
                    case name
                    case updatedAt = "updated_at"
                    case statusesURL = "statuses_url"
                    case forksCount = "forks_count"
                    case assigneesURL = "assignees_url"
                    case sshURL = "ssh_url"
                    case `public`
                    case hasWiki = "has_wiki"
                    case subscribersURL = "subscribers_url"
                    case watchersCount = "watchers_count"
                    case id
                    case hasDownloads = "has_downloads"
                    case gitCommitsURL = "git_commits_url"
                    case downloadsURL = "downloads_url"
                    case pullsURL = "pulls_url"
                    case homepage
                    case issueCommentURL = "issue_comment_url"
                    case hooksURL = "hooks_url"
                    case subscriptionURL = "subscription_url"
                    case milestonesURL = "milestones_url"
                    case svnURL = "svn_url"
                    case eventsURL = "events_url"
                    case gitTagsURL = "git_tags_url"
                    case teamsURL = "teams_url"
                    case commentsURL = "comments_url"
                    case openIssuesCount = "open_issues_count"
                    case keysURL = "keys_url"
                    case gitURL = "git_url"
                    case contributorsURL = "contributors_url"
                    case size
                    case watchers
                }
            }

            struct Issue: Decodable {
                struct User: Decodable {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let receivedEventsURL: URL
                    let organizationsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    private enum CodingKeys: String, CodingKey {
                        case url
                        case gistsURL = "gists_url"
                        case gravatarID = "gravatar_id"
                        case type
                        case avatarURL = "avatar_url"
                        case subscriptionsURL = "subscriptions_url"
                        case receivedEventsURL = "received_events_url"
                        case organizationsURL = "organizations_url"
                        case reposURL = "repos_url"
                        case login
                        case id
                        case starredURL = "starred_url"
                        case eventsURL = "events_url"
                        case followersURL = "followers_url"
                        case followingURL = "following_url"
                    }
                }

                struct Assignee: Decodable {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let organizationsURL: URL
                    let receivedEventsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    private enum CodingKeys: String, CodingKey {
                        case url
                        case gistsURL = "gists_url"
                        case gravatarID = "gravatar_id"
                        case type
                        case avatarURL = "avatar_url"
                        case subscriptionsURL = "subscriptions_url"
                        case organizationsURL = "organizations_url"
                        case receivedEventsURL = "received_events_url"
                        case reposURL = "repos_url"
                        case login
                        case id
                        case starredURL = "starred_url"
                        case eventsURL = "events_url"
                        case followersURL = "followers_url"
                        case followingURL = "following_url"
                    }
                }

                let user: User
                let url: URL
                let htmlURL: URL
                let labelsURL: URL
                let createdAt: Date
                let closedAt: Date?
                let title: String
                let body: String
                let updatedAt: Date
                let number: Int
                let state: String
                let assignee: Assignee?
                let id: Int
                let eventsURL: URL
                let commentsURL: URL
                let comments: Int

                private enum CodingKeys: String, CodingKey {
                    case user
                    case url
                    case htmlURL = "html_url"
                    case labelsURL = "labels_url"
                    case createdAt = "created_at"
                    case closedAt = "closed_at"
                    case title
                    case body
                    case updatedAt = "updated_at"
                    case number
                    case state
                    case assignee
                    case id
                    case eventsURL = "events_url"
                    case commentsURL = "comments_url"
                    case comments
                }
            }

            struct Comment: Decodable {
                struct User: Decodable {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let receivedEventsURL: URL
                    let organizationsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    private enum CodingKeys: String, CodingKey {
                        case url
                        case gistsURL = "gists_url"
                        case gravatarID = "gravatar_id"
                        case type
                        case avatarURL = "avatar_url"
                        case subscriptionsURL = "subscriptions_url"
                        case receivedEventsURL = "received_events_url"
                        case organizationsURL = "organizations_url"
                        case reposURL = "repos_url"
                        case login
                        case id
                        case starredURL = "starred_url"
                        case eventsURL = "events_url"
                        case followersURL = "followers_url"
                        case followingURL = "following_url"
                    }
                }

                let user: User
                let url: URL
                let issueURL: URL
                let createdAt: Date
                let body: String
                let updatedAt: Date
                let id: Int

                private enum CodingKeys: String, CodingKey {
                    case user
                    case url
                    case issueURL = "issue_url"
                    case createdAt = "created_at"
                    case body
                    case updatedAt = "updated_at"
                    case id
                }
            }

            struct Page: Decodable {
                let pageName: String
                let htmlURL: URL
                let title: String
                let sha: String
                let action: String

                private enum CodingKeys: String, CodingKey {
                    case pageName = "page_name"
                    case htmlURL = "html_url"
                    case title
                    case sha
                    case action
                }
            }

            let commits: [Commit]?
            let distinctSize: Int?
            let ref: String?
            let pushID: Int?
            let head: String?
            let before: String?
            let size: Int?
            let description: String?
            let masterBranch: String?
            let refType: String?
            let forkee: Forkee?
            let action: String?
            let issue: Issue?
            let comment: Comment?
            let pages: [Page]?

            private enum CodingKeys: String, CodingKey {
                case commits
                case distinctSize = "distinct_size"
                case ref
                case pushID = "push_id"
                case head
                case before
                case size
                case description
                case masterBranch = "master_branch"
                case refType = "ref_type"
                case forkee
                case action
                case issue
                case comment
                case pages
            }
        }

        struct Org: Decodable {
            let gravatarID: String
            let login: String
            let avatarURL: URL
            let url: URL
            let id: Int

            private enum CodingKeys: String, CodingKey {
                case gravatarID = "gravatar_id"
                case login
                case avatarURL = "avatar_url"
                case url
                case id
            }
        }

        let type: String
        let createdAt: Date
        let `actor`: Actor
        let repo: Repo
        let `public`: Bool
        let payload: Payload
        let id: String
        let org: Org?

        private enum CodingKeys: String, CodingKey {
            case type
            case createdAt = "created_at"
            case `actor`
            case repo
            case `public`
            case payload
            case id
            case org
        }
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let list = try! decoder.decode([Event].self, from: githubEventsJSONData)

    assert(
        list[1].repo.url.absoluteString == "https://api.github.com/repos/noahlu/mockingbird"
    )
}

githubEventsSuite.benchmark("SwiftyJSON decoding") {
    struct Event {
        struct Actor {
            let gravatarID: String
            let login: String
            let avatarURL: URL
            let url: URL
            let id: Int

            init(json: SwiftyJSON.JSON) {
                gravatarID = json["gravatar_id"].stringValue
                login = json["login"].stringValue
                avatarURL = json["avatar_url"].urlValue
                url = json["url"].urlValue
                id = json["id"].intValue
            }
        }

        struct Repo {
            let url: URL
            let id: Int
            let name: String

            init(json: SwiftyJSON.JSON) {
                url = json["url"].urlValue
                id = json["id"].intValue
                name = json["name"].stringValue
            }
        }

        struct Payload {
            struct Commit {
                struct Author {
                    let email: String
                    let name: String

                    init(json: SwiftyJSON.JSON) {
                        email = json["email"].stringValue
                        name = json["name"].stringValue
                    }
                }

                let url: URL
                let message: String
                let distinct: Bool
                let sha: String
                let author: Author

                init(json: SwiftyJSON.JSON) {
                    url = json["url"].urlValue
                    message = json["message"].stringValue
                    distinct = json["distinct"].boolValue
                    sha = json["sha"].stringValue
                    author = .init(json: json["author"])
                }
            }

            struct Forkee {
                struct Owner {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let organizationsURL: URL
                    let receivedEventsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    init(json: SwiftyJSON.JSON) {
                        url = json["url"].urlValue
                        gistsURL = json["gists_url"].urlValue
                        gravatarID = json["gravatar_id"].stringValue
                        type = json["type"].stringValue
                        avatarURL = json["avatar_url"].urlValue
                        subscriptionsURL = json["subscriptions_url"].urlValue
                        organizationsURL = json["organizations_url"].urlValue
                        receivedEventsURL = json["received_events_url"].urlValue
                        reposURL = json["repos_url"].urlValue
                        login = json["login"].stringValue
                        id = json["id"].intValue
                        starredURL = json["starred_url"].urlValue
                        eventsURL = json["events_url"].urlValue
                        followersURL = json["followers_url"].urlValue
                        followingURL = json["following_url"].urlValue
                    }
                }

                let description: String
                let fork: Bool
                let url: URL
                let language: String
                let stargazersURL: URL
                let cloneURL: URL
                let tagsURL: URL
                let fullName: String
                let mergesURL: URL
                let forks: Int
                let `private`: Bool
                let gitRefsURL: URL
                let archiveURL: URL
                let collaboratorsURL: URL
                let owner: Owner
                let languagesURL: URL
                let treesURL: URL
                let labelsURL: URL
                let htmlURL: URL
                let pushedAt: Date
                let createdAt: Date
                let hasIssues: Bool
                let forksURL: URL
                let branchesURL: URL
                let commitsURL: URL
                let notificationsURL: URL
                let openIssues: Int
                let contentsURL: URL
                let blobsURL: URL
                let issuesURL: URL
                let compareURL: URL
                let issueEventsURL: URL
                let name: String
                let updatedAt: Date
                let statusesURL: URL
                let forksCount: Int
                let assigneesURL: URL
                let sshURL: String
                let `public`: Bool
                let hasWiki: Bool
                let subscribersURL: URL
                let watchersCount: Int
                let id: Int
                let hasDownloads: Bool
                let gitCommitsURL: URL
                let downloadsURL: URL
                let pullsURL: URL
                let homepage: String?
                let issueCommentURL: URL
                let hooksURL: URL
                let subscriptionURL: URL
                let milestonesURL: URL
                let svnURL: URL
                let eventsURL: URL
                let gitTagsURL: URL
                let teamsURL: URL
                let commentsURL: URL
                let openIssuesCount: Int
                let keysURL: URL
                let gitURL: URL
                let contributorsURL: URL
                let size: Int
                let watchers: Int

                init(json: SwiftyJSON.JSON) {
                    description = json["description"].stringValue
                    fork = json["fork"].boolValue
                    url = json["url"].urlValue
                    language = json["language"].stringValue
                    stargazersURL = json["stargazers_url"].urlValue
                    cloneURL = json["clone_url"].urlValue
                    tagsURL = json["tags_url"].urlValue
                    fullName = json["full_name"].stringValue
                    mergesURL = json["merges_url"].urlValue
                    forks = json["forks"].intValue
                    `private` = json["private"].boolValue
                    gitRefsURL = json["git_refs_url"].urlValue
                    archiveURL = json["archive_url"].urlValue
                    collaboratorsURL = json["collaborators_url"].urlValue
                    owner = .init(json: json["owner"])
                    languagesURL = json["languages_url"].urlValue
                    treesURL = json["trees_url"].urlValue
                    labelsURL = json["labels_url"].urlValue
                    htmlURL = json["html_url"].urlValue
                    pushedAt = json["pushed_at"].dateValue
                    createdAt = json["created_at"].dateValue
                    hasIssues = json["has_issues"].boolValue
                    forksURL = json["forks_url"].urlValue
                    branchesURL = json["branches_url"].urlValue
                    commitsURL = json["commits_url"].urlValue
                    notificationsURL = json["notifications_url"].urlValue
                    openIssues = json["open_issues"].intValue
                    contentsURL = json["contents_url"].urlValue
                    blobsURL = json["blobs_url"].urlValue
                    issuesURL = json["issues_url"].urlValue
                    compareURL = json["compare_url"].urlValue
                    issueEventsURL = json["issue_events_url"].urlValue
                    name = json["name"].stringValue
                    updatedAt = json["updated_at"].dateValue
                    statusesURL = json["statuses_url"].urlValue
                    forksCount = json["forks_count"].intValue
                    assigneesURL = json["assignees_url"].urlValue
                    sshURL = json["ssh_url"].stringValue
                    `public` = json["public"].boolValue
                    hasWiki = json["has_wiki"].boolValue
                    subscribersURL = json["subscribers_url"].urlValue
                    watchersCount = json["watchers_count"].intValue
                    id = json["id"].intValue
                    hasDownloads = json["has_downloads"].boolValue
                    gitCommitsURL = json["git_commits_url"].urlValue
                    downloadsURL = json["downloads_url"].urlValue
                    pullsURL = json["pulls_url"].urlValue
                    homepage = json["homepage"].string
                    issueCommentURL = json["issue_comment_url"].urlValue
                    hooksURL = json["hooks_url"].urlValue
                    subscriptionURL = json["subscription_url"].urlValue
                    milestonesURL = json["milestones_url"].urlValue
                    svnURL = json["svn_url"].urlValue
                    eventsURL = json["events_url"].urlValue
                    gitTagsURL = json["git_tags_url"].urlValue
                    teamsURL = json["teams_url"].urlValue
                    commentsURL = json["comments_url"].urlValue
                    openIssuesCount = json["open_issues_count"].intValue
                    keysURL = json["keys_url"].urlValue
                    gitURL = json["git_url"].urlValue
                    contributorsURL = json["contributors_url"].urlValue
                    size = json["size"].intValue
                    watchers = json["watchers"].intValue
                }
            }

            struct Issue {
                struct User {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let receivedEventsURL: URL
                    let organizationsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    init(json: SwiftyJSON.JSON) {
                        url = json["url"].urlValue
                        gistsURL = json["gists_url"].urlValue
                        gravatarID = json["gravatar_id"].stringValue
                        type = json["type"].stringValue
                        avatarURL = json["avatar_url"].urlValue
                        subscriptionsURL = json["subscriptions_url"].urlValue
                        receivedEventsURL = json["received_events_url"].urlValue
                        organizationsURL = json["organizations_url"].urlValue
                        reposURL = json["repos_url"].urlValue
                        login = json["login"].stringValue
                        id = json["id"].intValue
                        starredURL = json["starred_url"].urlValue
                        eventsURL = json["events_url"].urlValue
                        followersURL = json["followers_url"].urlValue
                        followingURL = json["following_url"].urlValue
                    }
                }

                struct Assignee {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let organizationsURL: URL
                    let receivedEventsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    init(json: SwiftyJSON.JSON) {
                        url = json["url"].urlValue
                        gistsURL = json["gists_url"].urlValue
                        gravatarID = json["gravatar_id"].stringValue
                        type = json["type"].stringValue
                        avatarURL = json["avatar_url"].urlValue
                        subscriptionsURL = json["subscriptions_url"].urlValue
                        organizationsURL = json["organizations_url"].urlValue
                        receivedEventsURL = json["received_events_url"].urlValue
                        reposURL = json["repos_url"].urlValue
                        login = json["login"].stringValue
                        id = json["id"].intValue
                        starredURL = json["starred_url"].urlValue
                        eventsURL = json["events_url"].urlValue
                        followersURL = json["followers_url"].urlValue
                        followingURL = json["following_url"].urlValue
                    }
                }

                let user: User
                let url: URL
                let htmlURL: URL
                let labelsURL: URL
                let createdAt: Date
                let closedAt: Date?
                let title: String
                let body: String
                let updatedAt: Date
                let number: Int
                let state: String
                let assignee: Assignee?
                let id: Int
                let eventsURL: URL
                let commentsURL: URL
                let comments: Int

                init(json: SwiftyJSON.JSON) {
                    user = .init(json: json["user"])
                    url = json["url"].urlValue
                    htmlURL = json["html_url"].urlValue
                    labelsURL = json["labels_url"].urlValue
                    createdAt = json["created_at"].dateValue
                    closedAt = json["closed_at"].dateValue
                    title = json["title"].stringValue
                    body = json["body"].stringValue
                    updatedAt = json["updated_at"].dateValue
                    number = json["number"].intValue
                    state = json["state"].stringValue
                    assignee = json["assignee"].emptyAsNil.map { .init(json: $0) }
                    id = json["id"].intValue
                    eventsURL = json["events_url"].urlValue
                    commentsURL = json["comments_url"].urlValue
                    comments = json["comments"].intValue
                }
            }

            struct Comment {
                struct User {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let receivedEventsURL: URL
                    let organizationsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    init(json: SwiftyJSON.JSON) {
                        url = json["url"].urlValue
                        gistsURL = json["gists_url"].urlValue
                        gravatarID = json["gravatar_id"].stringValue
                        type = json["type"].stringValue
                        avatarURL = json["avatar_url"].urlValue
                        subscriptionsURL = json["subscriptions_url"].urlValue
                        receivedEventsURL = json["received_events_url"].urlValue
                        organizationsURL = json["organizations_url"].urlValue
                        reposURL = json["repos_url"].urlValue
                        login = json["login"].stringValue
                        id = json["id"].intValue
                        starredURL = json["starred_url"].urlValue
                        eventsURL = json["events_url"].urlValue
                        followersURL = json["followers_url"].urlValue
                        followingURL = json["following_url"].urlValue
                    }
                }

                let user: User
                let url: URL
                let issueURL: URL
                let createdAt: Date
                let body: String
                let updatedAt: Date
                let id: Int

                init(json: SwiftyJSON.JSON) {
                    user = .init(json: json["user"])
                    url = json["url"].urlValue
                    issueURL = json["issue_url"].urlValue
                    createdAt = json["created_at"].dateValue
                    body = json["body"].stringValue
                    updatedAt = json["updated_at"].dateValue
                    id = json["id"].intValue
                }
            }

            struct Page {
                let pageName: String
                let htmlURL: URL
                let title: String
                let sha: String
                let action: String

                init(json: SwiftyJSON.JSON) {
                    pageName = json["page_name"].stringValue
                    htmlURL = json["html_url"].urlValue
                    title = json["title"].stringValue
                    sha = json["sha"].stringValue
                    action = json["action"].stringValue
                }
            }

            let commits: [Commit]?
            let distinctSize: Int?
            let ref: String?
            let pushID: Int?
            let head: String?
            let before: String?
            let size: Int?
            let description: String?
            let masterBranch: String?
            let refType: String?
            let forkee: Forkee?
            let action: String?
            let issue: Issue?
            let comment: Comment?
            let pages: [Page]?

            init(json: SwiftyJSON.JSON) {
                commits = json["commits"].array?.map { .init(json: $0) }
                distinctSize = json["distinct_size"].int
                ref = json["ref"].string
                pushID = json["push_id"].int
                head = json["head"].string
                before = json["before"].string
                size = json["size"].int
                description = json["description"].string
                masterBranch = json["master_branch"].string
                refType = json["ref_type"].string
                forkee = json["forkee"].emptyAsNil.map { .init(json: $0) }
                action = json["action"].stringValue
                issue = json["issue"].emptyAsNil.map { .init(json: $0) }
                comment = json["comment"].emptyAsNil.map { .init(json: $0) }
                pages = json["pages"].array?.map { .init(json: $0) }
            }
        }

        struct Org {
            let gravatarID: String
            let login: String
            let avatarURL: URL
            let url: URL
            let id: Int

            init(json: SwiftyJSON.JSON) {
                gravatarID = json["gravatar_id"].stringValue
                login = json["login"].stringValue
                avatarURL = json["avatar_url"].urlValue
                url = json["url"].urlValue
                id = json["id"].intValue
            }
        }

        let type: String
        let createdAt: Date
        let `actor`: Actor
        let repo: Repo
        let `public`: Bool
        let payload: Payload
        let id: String
        let org: Org?

        init(json: SwiftyJSON.JSON) {
            type = json["type"].stringValue
            createdAt = json["created_at"].dateValue
            `actor` = .init(json: json["actor"])
            repo = .init(json: json["repo"])
            `public` = json["public"].boolValue
            payload = .init(json: json["payload"])
            id = json["id"].stringValue
            org = json["org"].emptyAsNil.map { .init(json: $0) }
        }
    }

    struct Model {
        let list: [Event]

        init(json: SwiftyJSON.JSON) {
            list = json.arrayValue.map { .init(json: $0) }
        }
    }

    let model = try Model(json: SwiftyJSON.JSON(data: githubEventsJSONData))

    assert(
        model.list[1].repo.url.absoluteString == "https://api.github.com/repos/noahlu/mockingbird"
    )
}

githubEventsSuite.benchmark("Ananda decoding") {
    struct Event: AnandaModel {
        struct Actor: AnandaModel {
            let gravatarID: String
            let login: String
            let avatarURL: URL
            let url: URL
            let id: Int

            init(json: AnandaJSON) {
                gravatarID = json.gravatar_id.string()
                login = json.login.string()
                avatarURL = json.avatar_url.url()
                url = json["url"].url()
                id = json.id.int()
            }
        }

        struct Repo: AnandaModel {
            let url: URL
            let id: Int
            let name: String

            init(json: AnandaJSON) {
                url = json["url"].url()
                id = json.id.int()
                name = json.name.string()
            }
        }

        struct Payload: AnandaModel {
            struct Commit: AnandaModel {
                struct Author: AnandaModel {
                    let email: String
                    let name: String

                    init(json: AnandaJSON) {
                        email = json.email.string()
                        name = json.name.string()
                    }
                }

                let url: URL
                let message: String
                let distinct: Bool
                let sha: String
                let author: Author

                init(json: AnandaJSON) {
                    url = json["url"].url()
                    message = json.message.string()
                    distinct = json.distinct.bool()
                    sha = json.sha.string()
                    author = .init(json: json.author)
                }
            }

            struct Forkee: AnandaModel {
                struct Owner: AnandaModel {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let organizationsURL: URL
                    let receivedEventsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    init(json: AnandaJSON) {
                        url = json["url"].url()
                        gistsURL = json.gists_url.url()
                        gravatarID = json.gravatar_id.string()
                        type = json.type.string()
                        avatarURL = json.avatar_url.url()
                        subscriptionsURL = json.subscriptions_url.url()
                        organizationsURL = json.organizations_url.url()
                        receivedEventsURL = json.received_events_url.url()
                        reposURL = json.repos_url.url()
                        login = json.login.string()
                        id = json.id.int()
                        starredURL = json.starred_url.url()
                        eventsURL = json.events_url.url()
                        followersURL = json.followers_url.url()
                        followingURL = json.following_url.url()
                    }
                }

                let description: String
                let fork: Bool
                let url: URL
                let language: String
                let stargazersURL: URL
                let cloneURL: URL
                let tagsURL: URL
                let fullName: String
                let mergesURL: URL
                let forks: Int
                let `private`: Bool
                let gitRefsURL: URL
                let archiveURL: URL
                let collaboratorsURL: URL
                let owner: Owner
                let languagesURL: URL
                let treesURL: URL
                let labelsURL: URL
                let htmlURL: URL
                let pushedAt: Date
                let createdAt: Date
                let hasIssues: Bool
                let forksURL: URL
                let branchesURL: URL
                let commitsURL: URL
                let notificationsURL: URL
                let openIssues: Int
                let contentsURL: URL
                let blobsURL: URL
                let issuesURL: URL
                let compareURL: URL
                let issueEventsURL: URL
                let name: String
                let updatedAt: Date
                let statusesURL: URL
                let forksCount: Int
                let assigneesURL: URL
                let sshURL: String
                let `public`: Bool
                let hasWiki: Bool
                let subscribersURL: URL
                let watchersCount: Int
                let id: Int
                let hasDownloads: Bool
                let gitCommitsURL: URL
                let downloadsURL: URL
                let pullsURL: URL
                let homepage: String?
                let issueCommentURL: URL
                let hooksURL: URL
                let subscriptionURL: URL
                let milestonesURL: URL
                let svnURL: URL
                let eventsURL: URL
                let gitTagsURL: URL
                let teamsURL: URL
                let commentsURL: URL
                let openIssuesCount: Int
                let keysURL: URL
                let gitURL: URL
                let contributorsURL: URL
                let size: Int
                let watchers: Int

                init(json: AnandaJSON) {
                    description = json["description"].string()
                    fork = json.fork.bool()
                    url = json["url"].url()
                    language = json.language.string()
                    stargazersURL = json.stargazers_url.url()
                    cloneURL = json.clone_url.url()
                    tagsURL = json.tags_url.url()
                    fullName = json.full_name.string()
                    mergesURL = json.merges_url.url()
                    forks = json.forks.int()
                    `private` = json.private.bool()
                    gitRefsURL = json.git_refs_url.url()
                    archiveURL = json.archive_url.url()
                    collaboratorsURL = json.collaborators_url.url()
                    owner = .init(json: json.owner)
                    languagesURL = json.languages_url.url()
                    treesURL = json.trees_url.url()
                    labelsURL = json.labels_url.url()
                    htmlURL = json.html_url.url()
                    pushedAt = json.pushed_at.date()
                    createdAt = json.created_at.date()
                    hasIssues = json.has_issues.bool()
                    forksURL = json.forks_url.url()
                    branchesURL = json.branches_url.url()
                    commitsURL = json.commits_url.url()
                    notificationsURL = json.notifications_url.url()
                    openIssues = json.open_issues.int()
                    contentsURL = json.contents_url.url()
                    blobsURL = json.blobs_url.url()
                    issuesURL = json.issues_url.url()
                    compareURL = json.compare_url.url()
                    issueEventsURL = json.issue_events_url.url()
                    name = json.name.string()
                    updatedAt = json.updated_at.date()
                    statusesURL = json.statuses_url.url()
                    forksCount = json.forks_count.int()
                    assigneesURL = json.assignees_url.url()
                    sshURL = json.ssh_url.string()
                    `public` = json.public.bool()
                    hasWiki = json.has_wiki.bool()
                    subscribersURL = json.subscribers_url.url()
                    watchersCount = json.watchers_count.int()
                    id = json.id.int()
                    hasDownloads = json.has_downloads.bool()
                    gitCommitsURL = json.git_commits_url.url()
                    downloadsURL = json.downloads_url.url()
                    pullsURL = json.pulls_url.url()
                    homepage = json.homepage.string
                    issueCommentURL = json.issue_comment_url.url()
                    hooksURL = json.hooks_url.url()
                    subscriptionURL = json.subscription_url.url()
                    milestonesURL = json.milestones_url.url()
                    svnURL = json.svn_url.url()
                    eventsURL = json.events_url.url()
                    gitTagsURL = json.git_tags_url.url()
                    teamsURL = json.teams_url.url()
                    commentsURL = json.comments_url.url()
                    openIssuesCount = json.open_issues_count.int()
                    keysURL = json.keys_url.url()
                    gitURL = json.git_url.url()
                    contributorsURL = json.contributors_url.url()
                    size = json.size.int()
                    watchers = json.watchers.int()
                }
            }

            struct Issue: AnandaModel {
                struct User: AnandaModel {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let receivedEventsURL: URL
                    let organizationsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    init(json: AnandaJSON) {
                        url = json["url"].url()
                        gistsURL = json.gists_url.url()
                        gravatarID = json.gravatar_id.string()
                        type = json.type.string()
                        avatarURL = json.avatar_url.url()
                        subscriptionsURL = json.subscriptions_url.url()
                        receivedEventsURL = json.received_events_url.url()
                        organizationsURL = json.organizations_url.url()
                        reposURL = json.repos_url.url()
                        login = json.login.string()
                        id = json.id.int()
                        starredURL = json.starred_url.url()
                        eventsURL = json.events_url.url()
                        followersURL = json.followers_url.url()
                        followingURL = json.following_url.url()
                    }
                }

                struct Assignee: AnandaModel {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let organizationsURL: URL
                    let receivedEventsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    init(json: AnandaJSON) {
                        url = json["url"].url()
                        gistsURL = json.gists_url.url()
                        gravatarID = json.gravatar_id.string()
                        type = json.type.string()
                        avatarURL = json.avatar_url.url()
                        subscriptionsURL = json.subscriptions_url.url()
                        organizationsURL = json.organizations_url.url()
                        receivedEventsURL = json.received_events_url.url()
                        reposURL = json.repos_url.url()
                        login = json.login.string()
                        id = json.id.int()
                        starredURL = json.starred_url.url()
                        eventsURL = json.events_url.url()
                        followersURL = json.followers_url.url()
                        followingURL = json.following_url.url()
                    }
                }

                let user: User
                let url: URL
                let htmlURL: URL
                let labelsURL: URL
                let createdAt: Date
                let closedAt: Date?
                let title: String
                let body: String
                let updatedAt: Date
                let number: Int
                let state: String
                let assignee: Assignee?
                let id: Int
                let eventsURL: URL
                let commentsURL: URL
                let comments: Int

                init(json: AnandaJSON) {
                    user = .init(json: json.user)
                    url = json["url"].url()
                    htmlURL = json.html_url.url()
                    labelsURL = json.labels_url.url()
                    createdAt = json.created_at.date()
                    closedAt = json.closed_at.date
                    title = json.title.string()
                    body = json.body.string()
                    updatedAt = json.updated_at.date()
                    number = json.number.int()
                    state = json.state.string()
                    assignee = json.assignee.emptyAsNil.map { .init(json: $0) }
                    id = json.id.int()
                    eventsURL = json.events_url.url()
                    commentsURL = json.comments_url.url()
                    comments = json.comments.int()
                }
            }

            struct Comment: AnandaModel {
                struct User: AnandaModel {
                    let url: URL
                    let gistsURL: URL
                    let gravatarID: String
                    let type: String
                    let avatarURL: URL
                    let subscriptionsURL: URL
                    let receivedEventsURL: URL
                    let organizationsURL: URL
                    let reposURL: URL
                    let login: String
                    let id: Int
                    let starredURL: URL
                    let eventsURL: URL
                    let followersURL: URL
                    let followingURL: URL

                    init(json: AnandaJSON) {
                        url = json["url"].url()
                        gistsURL = json.gists_url.url()
                        gravatarID = json.gravatar_id.string()
                        type = json.type.string()
                        avatarURL = json.avatar_url.url()
                        subscriptionsURL = json.subscriptions_url.url()
                        receivedEventsURL = json.received_events_url.url()
                        organizationsURL = json.organizations_url.url()
                        reposURL = json.repos_url.url()
                        login = json.login.string()
                        id = json.id.int()
                        starredURL = json.starred_url.url()
                        eventsURL = json.events_url.url()
                        followersURL = json.followers_url.url()
                        followingURL = json.following_url.url()
                    }
                }

                let user: User
                let url: URL
                let issueURL: URL
                let createdAt: Date
                let body: String
                let updatedAt: Date
                let id: Int

                init(json: AnandaJSON) {
                    user = .init(json: json.user)
                    url = json["url"].url()
                    issueURL = json.issue_url.url()
                    createdAt = json.created_at.date()
                    body = json.body.string()
                    updatedAt = json.updated_at.date()
                    id = json.id.int()
                }
            }

            struct Page: AnandaModel {
                let pageName: String
                let htmlURL: URL
                let title: String
                let sha: String
                let action: String

                init(json: AnandaJSON) {
                    pageName = json.page_name.string()
                    htmlURL = json.html_url.url()
                    title = json.title.string()
                    sha = json.sha.string()
                    action = json.action.string()
                }
            }

            let commits: [Commit]?
            let distinctSize: Int?
            let ref: String?
            let pushID: Int?
            let head: String?
            let before: String?
            let size: Int?
            let description: String?
            let masterBranch: String?
            let refType: String?
            let forkee: Forkee?
            let action: String?
            let issue: Issue?
            let comment: Comment?
            let pages: [Page]?

            init(json: AnandaJSON) {
                commits = json.commits.array?.map { .init(json: $0) }
                distinctSize = json.distinct_size.int
                ref = json.ref.string
                pushID = json.push_id.int
                head = json.head.string
                before = json.before.string
                size = json.size.int
                description = json["description"].string
                masterBranch = json.master_branch.string
                refType = json.ref_type.string
                forkee = json.forkee.emptyAsNil.map { .init(json: $0) }
                action = json.action.string
                issue = json.issue.emptyAsNil.map { .init(json: $0) }
                comment = json.comment.emptyAsNil.map { .init(json: $0) }
                pages = json.pages.array?.map { .init(json: $0) }
            }
        }

        struct Org: AnandaModel {
            let gravatarID: String
            let login: String
            let avatarURL: URL
            let url: URL
            let id: Int

            init(json: AnandaJSON) {
                gravatarID = json.gravatar_id.string()
                login = json.login.string()
                avatarURL = json.avatar_url.url()
                url = json["url"].url()
                id = json.id.int()
            }
        }

        let type: String
        let createdAt: Date
        let `actor`: Actor
        let repo: Repo
        let `public`: Bool
        let payload: Payload
        let id: String
        let org: Org?

        init(json: AnandaJSON) {
            type = json.type.string()
            createdAt = json.created_at.date()
            `actor` = .init(json: json.actor)
            repo = .init(json: json.repo)
            `public` = json.public.bool()
            payload = .init(json: json.payload)
            id = json.id.string()
            org = json.org.emptyAsNil.map { .init(json: $0) }
        }
    }

    struct Model: AnandaModel {
        let list: [Event]

        init(json: AnandaJSON) {
            list = json.array().map { .init(json: $0) }
        }
    }

    let model = Model.decode(from: githubEventsJSONData)

    assert(
        model.list[1].repo.url.absoluteString == "https://api.github.com/repos/noahlu/mockingbird"
    )
}

githubEventsSuite.benchmark("Ananda decoding with Macro") {
    @AnandaInit
    struct Event: AnandaModel {
        @AnandaInit
        struct Actor: AnandaModel {
            @AnandaKey("gravatar_id")
            let gravatarID: String
            let login: String
            @AnandaKey("avatar_url")
            let avatarURL: URL
            let url: URL
            let id: Int
        }

        @AnandaInit
        struct Repo: AnandaModel {
            let url: URL
            let id: Int
            let name: String
        }

        @AnandaInit
        struct Payload: AnandaModel {
            @AnandaInit
            struct Commit: AnandaModel {
                @AnandaInit
                struct Author: AnandaModel {
                    let email: String
                    let name: String
                }

                let url: URL
                let message: String
                let distinct: Bool
                let sha: String
                let author: Author
            }

            @AnandaInit
            struct Forkee: AnandaModel {
                @AnandaInit
                struct Owner: AnandaModel {
                    let url: URL
                    @AnandaKey("gists_url")
                    let gistsURL: URL
                    @AnandaKey("gravatar_id")
                    let gravatarID: String
                    let type: String
                    @AnandaKey("avatar_url")
                    let avatarURL: URL
                    @AnandaKey("subscriptions_url")
                    let subscriptionsURL: URL
                    @AnandaKey("organizations_url")
                    let organizationsURL: URL
                    @AnandaKey("received_events_url")
                    let receivedEventsURL: URL
                    @AnandaKey("repos_url")
                    let reposURL: URL
                    let login: String
                    let id: Int
                    @AnandaKey("starred_url")
                    let starredURL: URL
                    @AnandaKey("events_url")
                    let eventsURL: URL
                    @AnandaKey("followers_url")
                    let followersURL: URL
                    @AnandaKey("following_url")
                    let followingURL: URL
                }

                let description: String
                let fork: Bool
                let url: URL
                let language: String
                @AnandaKey("stargazers_url")
                let stargazersURL: URL
                @AnandaKey("clone_url")
                let cloneURL: URL
                @AnandaKey("tags_url")
                let tagsURL: URL
                @AnandaKey("full_name")
                let fullName: String
                @AnandaKey("merges_url")
                let mergesURL: URL
                let forks: Int
                @AnandaKey("private")
                let `private`: Bool
                @AnandaKey("git_refs_url")
                let gitRefsURL: URL
                @AnandaKey("archive_url")
                let archiveURL: URL
                @AnandaKey("collaborators_url")
                let collaboratorsURL: URL
                let owner: Owner
                @AnandaKey("languages_url")
                let languagesURL: URL
                @AnandaKey("trees_url")
                let treesURL: URL
                @AnandaKey("labels_url")
                let labelsURL: URL
                @AnandaKey("html_url")
                let htmlURL: URL
                @AnandaKey("pushed_at")
                let pushedAt: Date
                @AnandaKey("created_at")
                let createdAt: Date
                @AnandaKey("has_issues")
                let hasIssues: Bool
                @AnandaKey("forks_url")
                let forksURL: URL
                @AnandaKey("branches_url")
                let branchesURL: URL
                @AnandaKey("commits_url")
                let commitsURL: URL
                @AnandaKey("notifications_url")
                let notificationsURL: URL
                @AnandaKey("open_issues")
                let openIssues: Int
                @AnandaKey("contents_url")
                let contentsURL: URL
                @AnandaKey("blobs_url")
                let blobsURL: URL
                @AnandaKey("issues_url")
                let issuesURL: URL
                @AnandaKey("compare_url")
                let compareURL: URL
                @AnandaKey("issue_events_url")
                let issueEventsURL: URL
                let name: String
                @AnandaKey("updated_at")
                let updatedAt: Date
                @AnandaKey("statuses_url")
                let statusesURL: URL
                @AnandaKey("forks_count")
                let forksCount: Int
                @AnandaKey("assignees_url")
                let assigneesURL: URL
                @AnandaKey("ssh_url")
                let sshURL: String
                @AnandaKey("public")
                let `public`: Bool
                @AnandaKey("has_wiki")
                let hasWiki: Bool
                @AnandaKey("subscribers_url")
                let subscribersURL: URL
                @AnandaKey("watchers_count")
                let watchersCount: Int
                let id: Int
                @AnandaKey("has_downloads")
                let hasDownloads: Bool
                @AnandaKey("git_commits_url")
                let gitCommitsURL: URL
                @AnandaKey("downloads_url")
                let downloadsURL: URL
                @AnandaKey("pulls_url")
                let pullsURL: URL
                let homepage: String?
                @AnandaKey("issue_comment_url")
                let issueCommentURL: URL
                @AnandaKey("hooks_url")
                let hooksURL: URL
                @AnandaKey("subscription_url")
                let subscriptionURL: URL
                @AnandaKey("milestones_url")
                let milestonesURL: URL
                @AnandaKey("svn_url")
                let svnURL: URL
                @AnandaKey("events_url")
                let eventsURL: URL
                @AnandaKey("git_tags_url")
                let gitTagsURL: URL
                @AnandaKey("teams_url")
                let teamsURL: URL
                @AnandaKey("comments_url")
                let commentsURL: URL
                @AnandaKey("open_issues_count")
                let openIssuesCount: Int
                @AnandaKey("keys_url")
                let keysURL: URL
                @AnandaKey("git_url")
                let gitURL: URL
                @AnandaKey("contributors_url")
                let contributorsURL: URL
                let size: Int
                let watchers: Int
            }

            @AnandaInit
            struct Issue: AnandaModel {
                @AnandaInit
                struct User: AnandaModel {
                    let url: URL
                    @AnandaKey("gists_url")
                    let gistsURL: URL
                    @AnandaKey("gravatar_id")
                    let gravatarID: String
                    let type: String
                    @AnandaKey("avatar_url")
                    let avatarURL: URL
                    @AnandaKey("subscriptions_url")
                    let subscriptionsURL: URL
                    @AnandaKey("received_events_url")
                    let receivedEventsURL: URL
                    @AnandaKey("organizations_url")
                    let organizationsURL: URL
                    @AnandaKey("repos_url")
                    let reposURL: URL
                    let login: String
                    let id: Int
                    @AnandaKey("starred_url")
                    let starredURL: URL
                    @AnandaKey("events_url")
                    let eventsURL: URL
                    @AnandaKey("followers_url")
                    let followersURL: URL
                    @AnandaKey("following_url")
                    let followingURL: URL
                }

                @AnandaInit
                struct Assignee: AnandaModel {
                    let url: URL
                    @AnandaKey("gists_url")
                    let gistsURL: URL
                    @AnandaKey("gravatar_id")
                    let gravatarID: String
                    let type: String
                    @AnandaKey("avatar_url")
                    let avatarURL: URL
                    @AnandaKey("subscriptions_url")
                    let subscriptionsURL: URL
                    @AnandaKey("organizations_url")
                    let organizationsURL: URL
                    @AnandaKey("received_events_url")
                    let receivedEventsURL: URL
                    @AnandaKey("repos_url")
                    let reposURL: URL
                    let login: String
                    let id: Int
                    @AnandaKey("starred_url")
                    let starredURL: URL
                    @AnandaKey("events_url")
                    let eventsURL: URL
                    @AnandaKey("followers_url")
                    let followersURL: URL
                    @AnandaKey("following_url")
                    let followingURL: URL
                }

                let user: User
                let url: URL
                @AnandaKey("html_url")
                let htmlURL: URL
                @AnandaKey("labels_url")
                let labelsURL: URL
                @AnandaKey("created_at")
                let createdAt: Date
                @AnandaKey("closed_at")
                let closedAt: Date?
                let title: String
                let body: String
                @AnandaKey("updated_at")
                let updatedAt: Date
                let number: Int
                let state: String
                let assignee: Assignee?
                let id: Int
                @AnandaKey("events_url")
                let eventsURL: URL
                @AnandaKey("comments_url")
                let commentsURL: URL
                let comments: Int
            }

            @AnandaInit
            struct Comment: AnandaModel {
                @AnandaInit
                struct User: AnandaModel {
                    let url: URL
                    @AnandaKey("gists_url")
                    let gistsURL: URL
                    @AnandaKey("gravatar_id")
                    let gravatarID: String
                    let type: String
                    @AnandaKey("avatar_url")
                    let avatarURL: URL
                    @AnandaKey("subscriptions_url")
                    let subscriptionsURL: URL
                    @AnandaKey("received_events_url")
                    let receivedEventsURL: URL
                    @AnandaKey("organizations_url")
                    let organizationsURL: URL
                    @AnandaKey("repos_url")
                    let reposURL: URL
                    let login: String
                    let id: Int
                    @AnandaKey("starred_url")
                    let starredURL: URL
                    @AnandaKey("events_url")
                    let eventsURL: URL
                    @AnandaKey("followers_url")
                    let followersURL: URL
                    @AnandaKey("following_url")
                    let followingURL: URL
                }

                let user: User
                let url: URL
                @AnandaKey("issue_url")
                let issueURL: URL
                @AnandaKey("created_at")
                let createdAt: Date
                let body: String
                @AnandaKey("updated_at")
                let updatedAt: Date
                let id: Int
            }

            @AnandaInit
            struct Page: AnandaModel {
                @AnandaKey("page_name")
                let pageName: String
                @AnandaKey("html_url")
                let htmlURL: URL
                let title: String
                let sha: String
                let action: String
            }

            let commits: [Commit]?
            @AnandaKey("distinct_size")
            let distinctSize: Int?
            let ref: String?
            @AnandaKey("push_id")
            let pushID: Int?
            let head: String?
            let before: String?
            let size: Int?
            let description: String?
            @AnandaKey("master_branch")
            let masterBranch: String?
            @AnandaKey("ref_type")
            let refType: String?
            let forkee: Forkee?
            let action: String?
            let issue: Issue?
            let comment: Comment?
            let pages: [Page]?
        }

        @AnandaInit
        struct Org: AnandaModel {
            @AnandaKey("gravatar_id")
            let gravatarID: String
            let login: String
            @AnandaKey("avatar_url")
            let avatarURL: URL
            let url: URL
            let id: Int
        }

        let type: String
        @AnandaKey("created_at")
        let createdAt: Date
        @AnandaKey("actor")
        let `actor`: Actor
        let repo: Repo
        @AnandaKey("public")
        let `public`: Bool
        let payload: Payload
        let id: String
        let org: Org?
    }

    struct Model: AnandaModel {
        let list: [Event]

        init(json: AnandaJSON) {
            list = json.array().map { .init(json: $0) }
        }
    }

    let model = Model.decode(from: githubEventsJSONData)

    assert(
        model.list[1].repo.url.absoluteString == "https://api.github.com/repos/noahlu/mockingbird"
    )
}

Benchmark.main([
    naiveSuite,
    githubEventsSuite,
])
