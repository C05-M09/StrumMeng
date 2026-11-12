import SwiftUI

struct SongListView: View {
    @State var viewModel: SongListViewModel
    var body: some View {
        ZStack {
            Image("Showtime_Assets/Showtime_BG").resizable().ignoresSafeArea()
            VStack(spacing: AppSpacing.l) {
                HStack {
                    BackButton { viewModel.back() }
                    Spacer()
                    Text("SHOWTIME").font(AppTypography.bungee(size: 52))
                        .foregroundStyle(AppColors.cream)
                    Spacer()
                }
                Text("Choose a song • Sample arrangements")
                    .font(AppTypography.dmMono(size: 22)).foregroundStyle(AppColors.cream)
                ScrollView {
                    VStack(spacing: AppSpacing.l) {
                        ForEach(viewModel.songs) { song in
                            Button { viewModel.select(song.id) } label: {
                                HStack(spacing: AppSpacing.l) {
                                    VStack(alignment: .leading, spacing: AppSpacing.s) {
                                        Text(song.title).font(AppTypography.bungee(size: 28))
                                        Text("BPM \(song.bpm)  •  1 min")
                                            .font(AppTypography.dmMono(size: 22))
                                    }
                                    Spacer()
                                    Image(systemName: "play.fill").font(.title)
                                }
                                .foregroundStyle(AppColors.brownInk)
                                .padding(AppSpacing.l)
                                .background(AppColors.cream, in: RoundedRectangle(cornerRadius: AppSpacing.radiusL))
                                .overlay(RoundedRectangle(cornerRadius: AppSpacing.radiusL)
                                    .stroke(AppColors.brownInk, lineWidth: AppSpacing.outline))
                            }.buttonStyle(.plain)
                        }
                    }.padding(AppSpacing.s)
                }
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 1000)
        }
        .navigationBarBackButtonHidden()
        .statusBarHidden()
    }
}
