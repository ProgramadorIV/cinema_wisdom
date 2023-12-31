import 'package:cinema_wisdom/presentation/widgets/videos/videos_by_movie.dart';
import 'package:cinema_wisdom/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';

import 'package:cinema_wisdom/domain/entities/movie.dart';
import 'package:cinema_wisdom/presentation/providers/providers.dart';

class MovieScreen extends ConsumerStatefulWidget {
  const MovieScreen({super.key, required this.movieId});

  final String movieId;

  static const String name = 'movie-screen';

  @override
  MovieScreenState createState() => MovieScreenState();
}

class MovieScreenState extends ConsumerState<MovieScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(movieDetailsProvider.notifier).loadMovie(widget.movieId);
    ref.read(actorsByMovieProvider.notifier).loadActor(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    final Movie? movie = ref.watch(movieDetailsProvider)[widget.movieId];

    if (movie == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    return FadeInRight(
      child: Scaffold(
        body: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            _CustomSliverAppBar(movie: movie),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _MovieDetails(movie: movie),
                childCount: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Podriamos tener este provider en un archivo a parte bien organizado pero solo se usa aqui

final isFavoriteProvider =
    FutureProvider.family.autoDispose((ref, int movieId) {
  final localStorageRepository = ref.watch(localStorageRepositoryProvider);
  return localStorageRepository.isFavoriteMovie(movieId);
});

class _CustomSliverAppBar extends ConsumerWidget {
  const _CustomSliverAppBar({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, ref) {
    final size = MediaQuery.of(context).size;
    final isFavoriteFuture = ref.watch(isFavoriteProvider(movie.id));
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return SliverAppBar(
      backgroundColor: Colors.black,
      expandedHeight: size.height * 0.7,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () async {
            await ref
                .read(favoritesMoviesProvider.notifier)
                .toggleFavorite(movie);
            ref.invalidate(isFavoriteProvider(movie.id));
          },
          icon: isFavoriteFuture.when(
            data: (isFavorite) => isFavorite
                ? const Icon(
                    Icons.favorite_rounded,
                    color: Colors.red,
                  )
                : const Icon(Icons.favorite_border),
            error: (_, __) => throw UnimplementedError(), //TODO
            loading: () => const CircularProgressIndicator(),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(top: 0),
        title: _CustomGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.7, 1],
          colors: [Colors.transparent, scaffoldBackgroundColor],
        ),
        background: Stack(
          children: [
            SizedBox.expand(
              child: Image.network(
                movie.posterPath,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress != null) return const SizedBox();
                  return child;
                },
              ),
            ),
            const _CustomGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: [0, 0.2],
              colors: [Colors.black54, Colors.transparent],
            ),
            const _CustomGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.4],
              colors: [Colors.black87, Colors.transparent],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomGradient extends StatelessWidget {
  const _CustomGradient({
    required this.begin,
    required this.end,
    required this.stops,
    required this.colors,
  });

  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<double> stops;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            stops: stops,
            colors: colors,
          ),
        ),
      ),
    );
  }
}

class _MovieDetails extends StatelessWidget {
  const _MovieDetails({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textThemes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntroDetails(movie: movie, size: size, textThemes: textThemes),
        _Genres(movie: movie),
        _ActorsByMovie(movie.id.toString()),
        VideoByMovie(movieId: movie.id),
        _SimilarMovies(movieId: movie.id),
      ],
    );
  }
}

class _Genres extends StatelessWidget {
  const _Genres({
    required this.movie,
  });

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20),
        scrollDirection: Axis.horizontal,
        itemCount: movie.genreIds.length,
        itemBuilder: (context, index) {
          return FadeInRight(
            duration: const Duration(seconds: 1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(movie.genreIds[index]),
                shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          );
        },
      ),
      // child: Row(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: [
      //     // ...movie.genreIds.map(
      //     //   (gender) => Container(
      //     //     margin: const EdgeInsets.only(right: 8),
      //     //     child: Chip(
      //     //       label: Text(gender),
      //     //       shape: BeveledRectangleBorder(
      //     //           borderRadius: BorderRadius.circular(20)),
      //     //     ),
      //     //   ),
      //     // ),

      //   ],
      // ),
    );
  }
}

class _IntroDetails extends StatelessWidget {
  const _IntroDetails({
    required this.movie,
    required this.size,
    required this.textThemes,
  });

  final Movie movie;
  final Size size;
  final TextTheme textThemes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  movie.posterPath,
                  width: size.width * 0.3,
                ),
              ),
              SizedBox(
                width: size.width * 0.3,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                          'Votes: ${movie.voteAverage.toStringAsPrecision(2)}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: (size.width - 38) * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    movie.title,
                    style: textThemes.titleLarge,
                  ),
                ),
                Text(
                  movie.overview,
                  style: textThemes.bodyLarge,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActorsByMovie extends ConsumerWidget {
  const _ActorsByMovie(this.movieId);

  final String movieId;

  @override
  Widget build(BuildContext context, ref) {
    final actorsByMovie = ref.watch(actorsByMovieProvider)[movieId] ?? [];

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actorsByMovie.length,
        itemBuilder: (context, index) {
          final actor = actorsByMovie[index];
          return Container(
            padding: const EdgeInsets.all(8),
            width: 120,
            child: Column(
              children: [
                FadeInRight(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FadeInImage(
                      height: 180,
                      width: 135,
                      fit: BoxFit.cover,
                      placeholder:
                          const AssetImage('assets/loaders/bottle-loader.gif'),
                      image: NetworkImage(actor.profilePath),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  actor.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                Text(
                  actor.character ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final FutureProviderFamily<List<Movie>, int> similarMoviesProvider =
    FutureProvider.family((ref, int movieId) {
  final movieRepository = ref.watch(movieRepositoryProvider);
  return movieRepository.getSimilarMovies(movieId);
});

class _SimilarMovies extends ConsumerWidget {
  const _SimilarMovies({required this.movieId});

  final int movieId;

  @override
  Widget build(BuildContext context, ref) {
    final similarMovies = ref.watch(similarMoviesProvider(movieId));

    return similarMovies.when(
      data: (movies) => _SimilarMoviesSlider(movies: movies),
      error: (_, __) => const Center(
        child: Text('Sorry, we were unable to fetch recommendations.'),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _SimilarMoviesSlider extends StatelessWidget {
  const _SimilarMoviesSlider({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30, top: 20),
      child: MovieHorizontalList(
        title: 'Recommendations',
        movies: movies,
      ),
    );
  }
}
