package com.liar.han1meplus.di

import com.liar.han1meplus.data.comment.CommentRepository
import com.liar.han1meplus.data.comment.CommentRepositoryImpl
import com.liar.han1meplus.data.download.DownloadRepository
import com.liar.han1meplus.data.download.DownloadRepositoryImpl
import com.liar.han1meplus.data.explore.ExploreRepository
import com.liar.han1meplus.data.explore.ExploreRepositoryImpl
import com.liar.han1meplus.data.following.FollowingRepository
import com.liar.han1meplus.data.following.FollowingRepositoryImpl
import com.liar.han1meplus.data.search.SearchRepository
import com.liar.han1meplus.data.search.SearchRepositoryImpl
import com.liar.han1meplus.data.video.VideoRepository
import com.liar.han1meplus.data.video.VideoRepositoryImpl
import com.liar.han1meplus.data.watch.WatchProgressRepository
import com.liar.han1meplus.data.watch.WatchProgressRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindExploreRepository(impl: ExploreRepositoryImpl): ExploreRepository

    @Binds
    @Singleton
    abstract fun bindFollowingRepository(impl: FollowingRepositoryImpl): FollowingRepository

    @Binds
    @Singleton
    abstract fun bindVideoRepository(impl: VideoRepositoryImpl): VideoRepository

    @Binds
    @Singleton
    abstract fun bindSearchRepository(impl: SearchRepositoryImpl): SearchRepository

    @Binds
    @Singleton
    abstract fun bindCommentRepository(impl: CommentRepositoryImpl): CommentRepository

    @Binds
    @Singleton
    abstract fun bindDownloadRepository(impl: DownloadRepositoryImpl): DownloadRepository

    @Binds
    @Singleton
    abstract fun bindWatchProgressRepository(impl: WatchProgressRepositoryImpl): WatchProgressRepository
}
