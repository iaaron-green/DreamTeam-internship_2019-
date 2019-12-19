package com.app.entities;

import com.app.DTO.DTOChatMessage;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;

@Entity
@Setter
@Getter
@EqualsAndHashCode
@Table(name = "chat_messages")
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private String message;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    public ChatMessage() {
    }

    public ChatMessage(Long userId, String message, Room room) {
        this.userId = userId;
        this.message = message;
        this.room = room;
    }

}
