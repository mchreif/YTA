import Foundation
import CoreLocation
import Observation

/// Single source of truth for all association content.
///
/// The website has no backend — every section is authored directly in
/// `index.html` / `yta-instagram-feed.js` — so the native app bundles the
/// same content and works fully offline.
///
/// **Integration point:** if YTA later exposes a content API (or the
/// Instagram Graph API is connected), replace the stored properties below
/// with `async` loads inside `refresh()` and the UI will update automatically
/// through Observation. The models are already `Sendable` and decodable-shaped
/// for that purpose.
@MainActor
@Observable
final class ContentStore {

    // MARK: Hero

    /// Hero headline (`<h1>` of the website).
    let heroTitle = "Springs, ruins & living heritage"
    /// Hero eyebrow line.
    let heroEyebrow = "Bekaa Valley · Lebanon"
    /// Organization name shown under the hero.
    let organizationName = "Yammouneh Tourism Association"

    /// Rotating "Discover" ticker items under the hero.
    let tickerItems: [String] = [
        "84 Natural Springs",
        "Roman Heritage",
        "Yammouneh Lake",
        "Music Festivals",
        "Eco-Tourism",
        "Sustainable Lebanon"
    ]

    // MARK: Mission

    let programs: [Program] = [
        Program(
            id: "p1",
            number: "01",
            title: "Yammouneh Music Festivals",
            details: "Organize large-scale music festivals that attract thousands of attendees with top singers and renowned dabke performers, while also hosting kids' festivals and magical Christmas villages that bring families together.",
            imageName: "mission-festivals",
            festivalVideos: [
                FestivalVideo(year: 2018, resourceName: "festival-2018"),
                FestivalVideo(year: 2019, resourceName: "festival-2019"),
                FestivalVideo(year: 2023, resourceName: "festival-2023")
            ]
        ),
        Program(
            id: "p2",
            number: "02",
            title: "Promote Sustainable Tourism",
            details: "Oversee sustainable development projects, champion eco-friendly tourism initiatives, and promote Lebanese unique touristic destinations locally and internationally.",
            imageName: "mission-raouche",
            festivalVideos: []
        ),
        Program(
            id: "p3",
            number: "03",
            title: "Preserve Heritage & Traditions",
            details: "Safeguard Lebanon's rich heritage by reviving folklore, preserving cultural traditions, and supporting rural industries through the promotion of local handicrafts and traditional products.",
            imageName: "mission-heritage",
            festivalVideos: []
        ),
        Program(
            id: "p4",
            number: "04",
            title: "Safeguard Natural Resources",
            details: "Protect natural lakes and rivers, safeguard water quality, and promote eco-tourism by raising environmental awareness and advancing sustainable conservation efforts.",
            imageName: "mission-nature",
            festivalVideos: []
        ),
        Program(
            id: "p5",
            number: "05",
            title: "Highlight Historic Landmarks",
            details: "Discover Lebanon's historic and religious landmarks - from ancient ruins to sacred sites. We preserve these treasures and invite visitors to explore their beauty, history, and cultural significance.",
            imageName: "mission-church",
            festivalVideos: []
        ),
        Program(
            id: "p6",
            number: "06",
            title: "Encourage Tourism Activities",
            details: "Organize trips across Lebanon, fostering cultural exchange and community engagement. Initiatives such as Walk & Talk offer opportunities to discover Lebanon's natural beauty while building connections and awareness.",
            imageName: "mission-harissa",
            festivalVideos: []
        )
    ]

    // MARK: Impact

    let impactIntro = "From grassroots festivals to reforestation and heritage projects, YTA measures success in communities engaged, traditions revived, and landscapes protected across the Bekaa Valley and beyond."

    let impactStats: [ImpactStat] = [
        ImpactStat(
            id: "festivals",
            value: 16,
            suffix: "+",
            label: "Festivals",
            details: "Large-scale cultural events featuring Lebanese music, dabke, and community celebration.",
            systemImage: "music.note.list"
        ),
        ImpactStat(
            id: "projects",
            value: 25,
            suffix: "+",
            label: "Projects Completed",
            details: "Tourism, conservation, and infrastructure initiatives delivered with local partners.",
            systemImage: "doc.text.fill"
        ),
        ImpactStat(
            id: "trees",
            value: 5000,
            suffix: "+",
            label: "Trees Planted",
            details: "Native reforestation around Yammouneh Lake and surrounding reserve areas.",
            systemImage: "tree.fill"
        )
    ]

    // MARK: Board

    let boardIntro = "A volunteer-led board committed to sustainable tourism, cultural preservation, and accountable stewardship of Yammouneh's natural heritage."

    let boardMembers: [BoardMember] = [
        BoardMember(id: "sofia", number: "01", name: "Sofia Chreif", role: "President", imageName: "avatar-sofia"),
        BoardMember(id: "doureid", number: "02", name: "Doureid Chreif", role: "Vice President", imageName: "avatar-doureid"),
        BoardMember(id: "mohamad", number: "03", name: "Mohamad Chreif", role: "Treasurer", imageName: "avatar-mohamad"),
        BoardMember(id: "hassan", number: "04", name: "Hassan Chreif", role: "Gov. Liaison", imageName: "avatar-hassan"),
        BoardMember(id: "ali", number: "05", name: "Ali Chreif", role: "Executive Officer", imageName: "avatar-ali")
    ]

    // MARK: Gallery

    /// The six official gallery scenes. Titles are the site's own captions;
    /// `season` is a visual grouping of what each photo depicts, and
    /// `storyProgramID` links each scene to the official mission text
    /// that narrates it (nature, landmarks, heritage) — no new copy.
    let galleryPhotos: [GalleryPhoto] = [
        GalleryPhoto(id: "yam1", number: "01", title: "Yammouneh River", imageName: "gallery-yam1", season: .summer, storyProgramID: "p4"),
        GalleryPhoto(id: "yam2", number: "02", title: "Roman Ruins", imageName: "gallery-yam2", season: .summer, storyProgramID: "p5"),
        GalleryPhoto(id: "yam6", number: "03", title: "Icy Beauty", imageName: "gallery-yam6", season: .winter, storyProgramID: "p4"),
        GalleryPhoto(id: "yam4", number: "04", title: "Autumn Reflections", imageName: "gallery-yam4", season: .autumn, storyProgramID: "p4"),
        GalleryPhoto(id: "yam7", number: "05", title: "Shared Heritage", imageName: "gallery-yam7", season: .autumn, storyProgramID: "p3"),
        GalleryPhoto(id: "yam8", number: "06", title: "Natural Reserve", imageName: "gallery-yam8", season: .summer, storyProgramID: "p4")
    ]

    /// Resolves the official mission program that narrates a scene.
    func program(withID id: String) -> Program? {
        programs.first { $0.id == id }
    }

    /// Other scenes shown in a detail screen's "Related" rail:
    /// same story program or same season, never the scene itself.
    func relatedPhotos(to photo: GalleryPhoto) -> [GalleryPhoto] {
        galleryPhotos.filter {
            $0.id != photo.id && ($0.storyProgramID == photo.storyProgramID || $0.season == photo.season)
        }
    }

    // MARK: Press

    /// Official framing copy; the articles themselves are fed live from
    /// ytalebanon.org — see `NewsStore`.
    let pressIntro = "Regional and international press coverage of YTA festivals, heritage initiatives, and Yammouneh's growing tourism profile."

    // MARK: Connect

    let connectLead = "Whether you are planning a visit, exploring partnership opportunities, or covering our festivals — our team is ready to welcome you to Yammouneh."

    let contact = ContactInfo(
        phoneDisplay: "+961 3 871 077",
        phoneURL: URL(string: "tel:+9613871077")!,
        email: "info@ytalebanon.org",
        emailURL: URL(string: "mailto:info@ytalebanon.org")!,
        tripGuideURL: URL(string: "mailto:info@ytalebanon.org?subject=Visit%20Yammouneh")!,
        addressLine: "Yammouneh, Bekaa, Lebanon",
        coordinate: CLLocationCoordinate2D(latitude: 34.0042, longitude: 36.0428),
        quickStats: [
            ContactInfo.QuickStat(value: "24h", label: "Typical response"),
            ContactInfo.QuickStat(value: "84+", label: "Natural springs"),
            ContactInfo.QuickStat(value: "Year-round", label: "Eco-tourism")
        ]
    )

    /// Copyright line from the website footer.
    let copyright = "© 2026 YTA Lebanon. All rights reserved."
}
