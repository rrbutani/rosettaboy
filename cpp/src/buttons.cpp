#include "buttons.h"

Buttons::Buttons(CPU *cpu, bool headless) {
    SDL_InitSubSystem(SDL_INIT_EVENTS);
    this->cpu = cpu;
    this->cycle = 0;
    this->headless = headless;
}

bool Buttons::tick() {
    this->cycle++;
    this->update_buttons();
    if(this->need_interrupt) {
        this->cpu->stop = false;
        this->cpu->interrupt(Interrupt::JOYPAD);
        this->need_interrupt = false;
    }
    if(this->cycle % 17556 == 20) {
        return this->handle_inputs();
    } else {
        return true;
    }
}

void Buttons::update_buttons() {
    u8 JOYP = ~this->cpu->ram->get(Mem::JOYP);
    JOYP &= 0xF0;
    if(JOYP & Joypad::MODE_DPAD) {
        if(this->up) JOYP |= Joypad::UP;
        if(this->down) JOYP |= Joypad::DOWN;
        if(this->left) JOYP |= Joypad::LEFT;
        if(this->right) JOYP |= Joypad::RIGHT;
    }
    if(JOYP & Joypad::MODE_BUTTONS) {
        if(this->b) JOYP |= Joypad::B;
        if(this->a) JOYP |= Joypad::A;
        if(this->start) JOYP |= Joypad::START;
        if(this->select) JOYP |= Joypad::SELECT;
    }
    this->cpu->ram->set(Mem::JOYP, ~JOYP);
}

bool Buttons::handle_inputs() {
    if(this->headless) {
        return true;
    }

    SDL_Event event;

    while(SDL_PollEvent(&event)) {
        if(event.type == SDL_QUIT) {
            return false;
        }
        if(event.type == SDL_KEYDOWN) {
            if(event.key.keysym.sym == SDLK_ESCAPE) return false;
            if(event.key.keysym.sym == SDLK_LSHIFT) this->turbo = true;

            this->need_interrupt = true;
            switch(event.key.keysym.sym) {
                case SDLK_UP: this->up = true; break;
                case SDLK_DOWN: this->down = true; break;
                case SDLK_LEFT: this->left = true; break;
                case SDLK_RIGHT: this->right = true; break;
                case SDLK_z: this->b = true; break;
                case SDLK_x: this->a = true; break;
                case SDLK_RETURN: this->start = true; break;
                case SDLK_SPACE: this->select = true; break;
                default: this->need_interrupt = false; break;
            }
        }
        if(event.type == SDL_KEYUP) {
            if(event.key.keysym.sym == SDLK_LSHIFT) this->turbo = false;

            switch(event.key.keysym.sym) {
                case SDLK_UP: this->up = false; break;
                case SDLK_DOWN: this->down = false; break;
                case SDLK_LEFT: this->left = false; break;
                case SDLK_RIGHT: this->right = false; break;
                case SDLK_z: this->b = false; break;
                case SDLK_x: this->a = false; break;
                case SDLK_RETURN: this->start = false; break;
                case SDLK_SPACE: this->select = false; break;
            }
        }
    }

    return true;
}
