import SwiftUI
import MapKit
import Combine

// MARK: - Tipos auxiliares

private enum SheetPosition {
    case collapsed
    case medium
    case expanded
}

private enum MapVisualMode {
    case standard
    case satellite
}

struct MapHomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var locationManager: LocationManager

    @StateObject private var groupRepo = GroupRepository()
    @StateObject private var presenceRepo = PresenceRepository()
    @StateObject private var searchVM = MapSearchVM()


    @State private var selectedGroup: UserGroup?
    @State private var showGroupPicker = false
    @State private var showSearch = false
    @State private var hasCenteredMap = false

    @State private var camera: MapCameraPosition = .automatic
    @State private var searchedLocation: CLLocationCoordinate2D?

    @State private var sheetPosition: SheetPosition = .medium
    @State private var mapMode: MapVisualMode = .standard
    @State private var showMapModes = false
    @State private var mapHeading: CLLocationDirection = 0

    var body: some View {
        GeometryReader { proxy in
            let totalHeight = proxy.size.height
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom

            ZStack {
                // MAPA
                theMap
                    .ignoresSafeArea()

                // TOP BAR
                VStack {
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .opacity(sheetPosition == .expanded ? 0 : 1)
                    Spacer()
                }

                // CONTROLES FLOTANTES
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        mapControls
                            .padding(.trailing, 16)
                            .padding(.bottom, controlsBottomPadding(safeBottom: safeBottom))
                            .opacity(sheetPosition == .expanded ? 0 : 1)
                    }
                }

                // SHEET DE MIEMBROS
                VStack {
                    Spacer()
                    membersBottomSheet(
                        totalHeight: totalHeight,
                        safeTop: safeTop,
                        safeBottom: safeBottom
                    )
                }
            }
        }
        .tint(Brand.tint)
        .onAppear {
            groupRepo.startListening()
        }
        .onDisappear {
            presenceRepo.stopListening()
            groupRepo.stopListening()
        }
        .onReceive(groupRepo.$groups) { groups in
            if selectedGroup == nil, let first = groups.first {
                setSelectedGroup(first)
            }
        }
        .onReceive(
            locationManager.$userLocation
                .compactMap { $0 }
                .removeDuplicates(by: { a, b in
                    a.latitude == b.latitude && a.longitude == b.longitude })
        ) { coord in
            if !hasCenteredMap {
                hasCenteredMap = true
                camera = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    )
                )
            }

            if let group = selectedGroup, let user = session.user {
                presenceRepo.updateMyPresence(
                    groupDocPath: group.docPath,
                    user: user,
                    coordinate: coord
                )
            }
        }
        .sheet(isPresented: $showGroupPicker) {
            EnhancedGroupPickerSheet(
                groups: groupRepo.groups,
                selected: selectedGroup,
                presenceRepo: presenceRepo
            ) { g in
                setSelectedGroup(g)
            }
            .tint(Brand.tint)
        }
        .sheet(isPresented: $showSearch) {
            EnhancedMapSearchView(vm: searchVM) { item in
                let coord = item.placemark.coordinate
                searchedLocation = coord
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    camera = .region(
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
        }
        .sheet(isPresented: $showMapModes) {
            EnhancedMapModesSheet(mapMode: $mapMode)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Funciones auxiliares

    private func sheetHeight(totalHeight: CGFloat, safeTop: CGFloat, safeBottom: CGFloat) -> CGFloat {
        let collapsed: CGFloat = 72
        let medium: CGFloat = 190
        let expanded: CGFloat = totalHeight - safeTop - 8

        switch sheetPosition {
        case .collapsed: return collapsed
        case .medium: return medium
        case .expanded: return expanded
        }
    }

    private func controlsBottomPadding(safeBottom: CGFloat) -> CGFloat {
        switch sheetPosition {
        case .collapsed: return 120 + safeBottom / 2
        case .medium: return 210 + safeBottom / 2
        case .expanded: return 250 + safeBottom / 2
        }
    }

    private func handleSheetDrag(translation: CGFloat) {
        let threshold: CGFloat = 40
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if translation < -threshold {
                switch sheetPosition {
                case .collapsed: sheetPosition = .medium
                case .medium: sheetPosition = .expanded
                case .expanded: break
                }
            } else if translation > threshold {
                switch sheetPosition {
                case .expanded: sheetPosition = .medium
                case .medium: sheetPosition = .collapsed
                case .collapsed: break
                }
            }
        }
    }

    // MARK: - Mapa

    private var theMap: some View {
        Map(position: $camera) {
            // Yo
            if let me = locationManager.userLocation {
                Annotation("Yo", coordinate: me) {
                    MePin(user: session.user, heading: locationManager.deviceHeading, mapHeading: mapHeading)
                }
            }

            // Miembros
            ForEach(presenceRepo.members) { m in
                if let coord = m.coordinate {
                    Annotation(m.displayName, coordinate: coord) {
                        AvatarPin(member: m)
                    }
                }
            }
            
            // Lugar buscado
            if let searched = searchedLocation {
                Annotation("", coordinate: searched) {
                    SearchedLocationPin()
                }
            }
        }
        .mapStyle(mapMode == .standard ? .standard : .imagery)
        .onMapCameraChange { context in
            self.mapHeading = context.camera.heading
        }
    }

    // MARK: - Controles flotantes

    private var mapControls: some View {
        VStack(spacing: 12) {
            Button {
                showMapModes = true
            } label: {
                Image(systemName: "map")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(.ultraThinMaterial)
                    )
            }
            .clipShape(Circle())
            
            Button {
                if let coord = locationManager.userLocation {
                    searchedLocation = nil
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        camera = .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                    }
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(.ultraThinMaterial)
                    )
            }
            .clipShape(Circle())
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top bar simplificada
    private var topBar: some View {
        HStack(spacing: 12) {
            // Grupo - SOLO NOMBRE
            Button {
                showGroupPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Brand.tint)
                    
                    Text(selectedGroup?.name ?? "Seleccionar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer()

            // Buscar
            Button {
                showSearch = true
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Brand.tint.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Brand.tint)
                    }

                    Text("Buscar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.leading, 8)
                .padding(.trailing, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    // MARK: - Bottom sheet

    @ViewBuilder
    private func membersBottomSheet(totalHeight: CGFloat, safeTop: CGFloat, safeBottom: CGFloat) -> some View {
        let height = sheetHeight(totalHeight: totalHeight, safeTop: safeTop, safeBottom: safeBottom)

        VStack(spacing: 0) {
            HStack {
                 Spacer()
                 Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 40, height: 4).padding(.top, 6)
                 Spacer()
            }

            HStack(alignment: .center) {
                Text("Miembros del grupo")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if let name = selectedGroup?.name {
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            if sheetPosition == .collapsed {
                Spacer(minLength: 4)
            } else if sheetPosition == .medium {
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                if presenceRepo.members.isEmpty {
                    VStack {
                        Spacer()
                        EmptyMembersView(
                            title: selectedGroup == nil
                                ? "Selecciona un grupo"
                                : "Sin miembros conectados"
                        )
                        Spacer()
                    }
                    .padding(.bottom, 10)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(presenceRepo.members) { member in
                                MemberRowCompact(member: member) {
                                    if let coord = member.coordinate {
                                        searchedLocation = nil
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            camera = .region(
                                                MKCoordinateRegion(
                                                    center: coord,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                                                )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                }
            } else {
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                if presenceRepo.members.isEmpty {
                    VStack {
                        Spacer()
                        EmptyMembersView(
                            title: selectedGroup == nil
                                ? "Selecciona un grupo"
                                : "Sin miembros conectados"
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(presenceRepo.members) { member in
                                MemberRowFull(member: member) {
                                    if let coord = member.coordinate {
                                        searchedLocation = nil
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            camera = .region(
                                                MKCoordinateRegion(
                                                    center: coord,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                                                )
                                            )
                                        }
                                    }
                                }
                                Divider()
                                    .padding(.leading, 88)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26))
        .gesture(
            DragGesture()
                .onEnded { value in
                    handleSheetDrag(translation: value.translation.height)
                }
        )
    }

    private func setSelectedGroup(_ g: UserGroup) {
        selectedGroup = g
        presenceRepo.startListening(groupDocPath: g.docPath)
    }
}

// MARK: - Pin de ubicación buscada

private struct SearchedLocationPin: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Brand.tint)
                    .frame(width: 36, height: 36)
                    .shadow(color: Brand.tint.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: "mappin")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Pins de usuarios

private struct MePin: View {
    let user: User?
    let heading: CLLocationDirection
    let mapHeading: CLLocationDirection

    var body: some View {
        ZStack {
            if let user = user, let url = user.photoURL {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(
                        LinearGradient(colors: [.blue, .cyan],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            } else if let user = user {
                Circle()
                    .fill(
                        LinearGradient(colors: [.blue, .cyan],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                Circle()
                    .fill(Brand.tint)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 18))
                    )
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }

            ZStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(y: -25)
            }
            .rotationEffect(.degrees(heading - mapHeading))
        }
    }
}

private struct AvatarPin: View {
    let member: MemberPresence

    var body: some View {
        VStack(spacing: 2) {
            if let url = member.photoURL {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(.gray.opacity(0.3))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2.5))
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
            } else {
                Circle()
                    .fill(Brand.tint)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(initials(member.displayName))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .overlay(Circle().stroke(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
            }

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .offset(y: -3)
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(second)"
    }
}

// MARK: - Filas de miembros

private struct MemberRowCompact: View {
    let member: MemberPresence
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let url = member.photoURL {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(.gray.opacity(0.2))
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Brand.tint.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(initials(member.displayName))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Brand.tint)
                        )
                }

                Text(member.displayName.split(separator: " ").first ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator:  " ")
        let first = parts.first?.prefix(1) ?? ""
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(second)"
    }
}

private struct MemberRowFull: View {
    let member: MemberPresence
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                if let url = member.photoURL {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(.gray.opacity(0.2))
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Brand.tint.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text(initials(member.displayName))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Brand.tint)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(member.displayName)
                        .font(.system(size: 17, weight: .semibold))

                    Text("Compartiendo ubicación")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(second)"
    }
}

private struct EmptyMembersView: View {
    let title: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Búsqueda mejorada

private struct EnhancedMapSearchView: View {
    @ObservedObject var vm: MapSearchVM
    let onSelectLocation: (MKMapItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barra de búsqueda
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        TextField("Buscar lugares", text: $searchText)
                            .font(.system(size: 16))
                            .submitLabel(.search)
                            .onSubmit {
                                vm.search(query: searchText)
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                vm.results = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()

                // Resultados
                if vm.results.isEmpty && searchText.isEmpty {
                    emptySearchState
                } else if vm.results.isEmpty && !searchText.isEmpty {
                    noResultsState
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Buscar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "map.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Brand.tint.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Busca cualquier lugar")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Restaurantes, parques, direcciones\ny mucho más")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("Sin resultados")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Intenta con otra búsqueda")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
    
    private var searchResultsList: some View {
        List {
            ForEach(vm.results, id: \.self) { item in
                Button {
                    onSelectLocation(item)
                    dismiss()
                } label: {
                    SearchResultRow(item: item)
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct SearchResultRow: View {
    let item: MKMapItem
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Brand.tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconForCategory)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Brand.tint)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Ubicación")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                if let address = formatAddress(item.placemark) {
                    Text(address)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(45))
        }
        .padding(.vertical, 6)
    }
    
    private var iconForCategory: String {
        guard let category = item.pointOfInterestCategory else {
            return "mappin.circle.fill"
        }
        
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .hospital: return "cross.fill"
        case .park: return "leaf.fill"
        case .school: return "book.fill"
        case .store: return "bag.fill"
        case .gasStation: return "fuelpump.fill"
        case .hotel: return "bed.double.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        var components: [String] = []
        
        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

// MARK: - Selector de grupos mejorado

private struct EnhancedGroupPickerSheet: View {
    let groups: [UserGroup]
    let selected: UserGroup?
    let presenceRepo: PresenceRepository
    let onPick: (UserGroup) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                if groups.isEmpty {
                    emptyState
                } else {
                    groupsList
                }
            }
            .navigationTitle("Grupos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Brand.tint.opacity(0.4))
            
            VStack(spacing: 8) {
                Text("No tienes grupos")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Crea un grupo para comenzar a\ncompartir tu ubicación con otros")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var groupsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(groups) { group in
                    EnhancedGroupCard(
                        group: group,
                        isSelected: group.id == selected?.id,
                        memberCount: getMemberCount(for: group)
                    ) {
                        onPick(group)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }
    
    private func getMemberCount(for group: UserGroup) -> Int {
        // Aquí podrías obtener el conteo real si lo tienes disponible
        return presenceRepo.members.count
    }
}

private struct EnhancedGroupCard: View {
    let group: UserGroup
    let isSelected: Bool
    let memberCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icono grande del grupo
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Brand.tint.opacity(0.15) : Color.clear)
                        .frame(width: 64, height: 64)
                                        
                    Image(systemName: isSelected ? "person.3.fill" : "person.3")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(isSelected ? Brand.tint : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                        Text("\(memberCount) miembros")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Brand.tint)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modos de mapa mejorado

private struct EnhancedMapModesSheet: View {
    @Binding var mapMode: MapVisualMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tipo de Mapa")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Selecciona cómo visualizar el mapa")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Opciones de mapa
            HStack(spacing: 16) {
                EnhancedMapModeButton(
                    title: "Estándar",
                    subtitle: "Calles y etiquetas",
                    icon: "map.fill",
                    isSelected: mapMode == .standard
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        mapMode = .standard
                    }
                }
                
                EnhancedMapModeButton(
                    title: "Satélite",
                    subtitle: "Vista aérea",
                    icon: "globe.americas.fill",
                    isSelected: mapMode == .satellite
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        mapMode = .satellite
                    }
                }
            }
            
            Spacer()
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .presentationBackground(.ultraThinMaterial)
    }
}

private struct EnhancedMapModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(isSelected ? Brand.tint : .secondary)
                        .frame(height: 90)
                        .frame(maxWidth: .infinity)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Brand.tint.opacity(isSelected ? 0.2 : 0))
                )
                
                VStack(spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MapHomeView()
        .environmentObject(SessionStore.shared)
        .environmentObject(LocationManager())
}
